import org.victor.*;

// MEL upload consignment note general funcs

MEL_EQU_ROWS_START = 17;

void toggButts(boolean iwhat)
{
	Object[] bb = { uplassets_b, savelist_b };
	for(i=0;i<bb.length;i++)
	{
		bb[i].setDisabled(iwhat);
	}
}

// itype: 1=mel-acceptance, 2=rw-location
void setMELCSGN_flags(int itype, String iwhat)
{
	if(glob_sel_csgn.equals("")) return;
	sqlstm = ""; pobj = null;
	switch(itype)
	{
		case 1:
			sqlstm = "update mel_csgn set mel_accept='" + iwhat + "' where origid=" + glob_sel_csgn;
			pobj = melaccpt_pop;
			break;
		case 2:
			sqlstm = "update mel_csgn set rwlocation='" + iwhat + "' where origid=" + glob_sel_csgn;
			pobj = locationpop;
			break;
	}
	if(!sqlstm.equals(""))
	{
		sqlhand.gpSqlExecuter(sqlstm);
		loadCSGN(last_list_csgn);
		pobj.close();	
	}
}

void rawUploadConsignment()
{
	if(glob_sel_csgn.equals("")) return;

	csgn_upload_data = new uploadedWorksheet();
	csgn_upload_data.getUploadFileData();
	if(csgn_upload_data.thefiledata == null)
	{
		guihand.showMessageBox("ERR: Invalid worksheet");
		return;
	}

	byte[] kry = new byte[csgn_upload_data.thefiledata.available()];
	csgn_upload_data.thefiledata.read( kry,0,csgn_upload_data.thefiledata.available() );
	tfnm = session.getWebApp().getRealPath("sharedocs/melcsgn/" + csgn_upload_data.thefilename);
	outstream = new FileOutputStream(tfnm);
	outstream.write(kry);
	outstream.close();
	csgn_upload_data.thefiledata.reset();

	try
	{
	tfnm = session.getWebApp().getRealPath("sharedocs/melcsgn/" + csgn_upload_data.thefilename);
	saveFileToDMS_2( JN_linkcode(), csgn_upload_data.thefilename, tfnm, "application/vnd.ms-excel", "xls", "Uploaded MEL consignment-note" );
	} catch (Exception e) { guihand.showMessageBox("ERR: Uploaded file not save to database.."); }

	fillDocumentsList(documents_holder,MEL_CSGN_PREFIX,glob_sel_csgn);

	processConsignmentUpload();
	//rental_sched_filename.setValue( kiboo.checkNullString(rentalsched_data.thefilename) );
}

Object[] csgnasshd =
{
	new listboxHeaderWidthObj("origid",false,""),
	new listboxHeaderWidthObj("Contract #",true,""),
	new listboxHeaderWidthObj("Serial Number",true,""),
	new listboxHeaderWidthObj("Asset Number (MEL Ref)",true,""),
	new listboxHeaderWidthObj("Item Description",true,""),
	new listboxHeaderWidthObj("Asset Category",true,""),
	new listboxHeaderWidthObj("Make",true,""),
	new listboxHeaderWidthObj("Model",true,""),
	new listboxHeaderWidthObj("Processor Or Monitor Type",true,""),
	new listboxHeaderWidthObj("Processor Speed Or Monitor Size",true,""),
	new listboxHeaderWidthObj("HDD Size",true,""),
	new listboxHeaderWidthObj("RAM",true,""),
};

void processConsignmentUpload() // Process the MEL csgn and insert items into table
{
	InputStream inps = null;
	org.apache.poi.hssf.usermodel.HSSFRow trow;
	Cell tcell;
	HashMap hm = new HashMap(); // check for dups s/nums

	try
	{
		if(csgn_upload_data == null) return;
		if(csgn_upload_data.thefiledata == null) return;
		if(csgn_upload_data.thefiledata instanceof java.io.ByteArrayInputStream)
			inps = csgn_upload_data.thefiledata;
		else
			inps = new ByteArrayInputStream(csgn_upload_data.thefiledata);
	}
	catch (Exception e) { guihand.showMessageBox("ERR: Invalid worksheet.."); return; }

	HSSFWorkbook excelWB = new HSSFWorkbook(inps);
	FormulaEvaluator evaluator = excelWB.getCreationHelper().createFormulaEvaluator();

	sht0 = excelWB.getSheetAt(0);
	numrows = sht0.getPhysicalNumberOfRows();

	String[] clm = new String[11];

	Listbox newlb = lbhand.makeVWListbox_Width(csgnasset_holder, csgnasshd, "csgnassets_lb", 20);
	uplocount = 0;
	unkwncount = 1; // to cater for unknown MEL serial-numbers
	usedmelassettag = false;

	for(i=MEL_EQU_ROWS_START; i<numrows; i++)
	{
		trow = sht0.getRow(i); if(trow == null) continue;
		tcell = trow.getCell(0); if(tcell == null) continue;

		clm[0] = "";
		try { clm[0] = POI_GetCellContentString(tcell,evaluator,"").trim(); } catch (Exception e) {}
		clm[0] = clm[0].toUpperCase();

		if(!clm[0].equals("") && !clm[0].equals("PACKING REMARK") && !clm[0].equals("REMARKS:")) // HARDCODED string checking
		{
			try
			{
				tcell = trow.getCell(1);
				clm[1] = POI_GetCellContentString(tcell,evaluator,"").trim(); // get snum
				clm[1] = clm[1].replaceAll(",",""); // 12/01/2015: sometimes snum imported as no. which contains , formatting
				if(!clm[1].equals(""))
				{
					for(x=2; x<11; x++)
					{
						tcell = trow.getCell(x);
						clm[x] = POI_GetCellContentString(tcell,evaluator,"").trim();
						if(x == 2) // MEL asset-tag formatted as no., remove ","
							clm[x] = clm[x].replaceAll(",","");
					}

					if(clm[1].toUpperCase().equals("NULL")) // if null/unknown MEL snums, take MEL asset-tag as snum
					{
						clm[1] = clm[2];
						usedmelassettag = true;
					}

					if( !hm.containsKey(clm[1]) && !hm.containsKey(clm[2]) ) // make sure no dup s/num and mel-asset-tag
					{
						lbhand.insertListItems(newlb,clm,"false","");
						hm.put(clm[1],1); // put s/num and mel-asset-tag into hashmap for dups checking
						hm.put(clm[2],1);
						uplocount++;
					}
					else
					{
						guihand.showMessageBox("ERR: Duplicates found : " + clm[1] + " / " + clm[2]);
						csgnassets_lb.setParent(null); // remove the listbox
						return;
					}
				}
			}
			catch (Exception e) {}
		}
	}
	uplcount_lbl.setValue("Items uploaded: " + uplocount.toString());

	mf = (usedmelassettag) ? "1" : "0";
	sqlstm = "update mel_csgn set usedmelassettag=" + mf + " where origid=" + glob_sel_csgn;
	sqlhand.gpSqlExecuter(sqlstm); // upload mel_csgn.usedmelassettag flag
}

/**
 * MEL inventory listbox double-clicker
 */
class midclicker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		glob_sel_inventory_obj = event.getTarget();
		if(glob_sel_inventory_obj != null)
		{
			glob_sel_inventory = lbhand.getListcellItemLabel(glob_sel_inventory_obj,0);

			// populate 'em textbox in popup for editing
			e_serial_no.setValue( lbhand.getListcellItemLabel(glob_sel_inventory_obj,2) );
			e_mel_asset.setValue( lbhand.getListcellItemLabel(glob_sel_inventory_obj,3) );
			edititem_pop.open(glob_sel_inventory_obj);
		}
	}
}
melinvdclik = new midclicker();

void showConsignmentThings()
{
	if(csgnasset_holder.getFellowIfAny("csgnassets_lb") != null) csgnassets_lb.setParent(null); // remove prev lb

	if(!glob_csgn_qty.equals("") && !glob_csgn_qty.equals("0"))
	{
		Listbox newlb = lbhand.makeVWListbox_Width(csgnasset_holder, csgnasshd, "csgnassets_lb", 20);
		sqlstm = "select * from mel_inventory where parent_id=" + glob_sel_csgn;
		rcs = sqlhand.gpSqlGetRows(sqlstm);
		ArrayList kabom = new ArrayList();
		String[] fl = { "origid","contract_no","serial_no","mel_asset","item_desc","item_type","brand_make","model","sub_type","sub_spec","hdd","ram" };
		for(d : rcs)
		{
			ngfun.popuListitems_Data(kabom,fl,d);
			lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
			kabom.clear();
		}
		lbhand.setDoubleClick_ListItems(newlb,melinvdclik);
	}

	fillDocumentsList(documents_holder,MEL_CSGN_PREFIX,glob_sel_csgn);

	toggButts( (!glob_csgn_stat.equals("COMMIT")) ? false : true );
	workarea.setVisible(true);
}

Object[] csgnlb_headers =
{
	new listboxHeaderWidthObj("CSGN",true,"40px"),
	new listboxHeaderWidthObj("Dated",true,"70px"),
	new listboxHeaderWidthObj("MEL REF",true,"90px"),
	new listboxHeaderWidthObj("UplBy",true,"80px"),
	new listboxHeaderWidthObj("ETA",true,"80px"),
	new listboxHeaderWidthObj("Location",true,"80px"), // 5
	new listboxHeaderWidthObj("Status",true,"70px"),
	new listboxHeaderWidthObj("Notes",true,""),
	new listboxHeaderWidthObj("Qty",true,"50px"),
	new listboxHeaderWidthObj("UseMEL",true,"40px"),
	new listboxHeaderWidthObj("Acceptance",true,"60px"),
};

class csgnlbClick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_sel_csgn = lbhand.getListcellItemLabel(isel,0);
		glob_sel_melcsgn = lbhand.getListcellItemLabel(isel,2);

		glob_sel_loca = lbhand.getListcellItemLabel(isel,5);
		glob_sel_notes = lbhand.getListcellItemLabel(isel,7);

		glob_csgn_stat = lbhand.getListcellItemLabel(isel,6);
		glob_csgn_qty = lbhand.getListcellItemLabel(isel,8); // to see got equips or not

		csgn_sel_item = isel;
		showConsignmentThings();
	}
}
csgnclkier = new csgnlbClick();

void loadCSGN(int itype)
{
	last_list_csgn = itype;
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	loca = p_location.getSelectedItem().getLabel();

	Listbox newlb = lbhand.makeVWListbox_Width(csgnholder, csgnlb_headers, "csgn_lb", 3);

	sqlstm = "select mn.origid,mn.datecreated,mn.csgn,mn.mel_user,mn.mstatus,mn.extranotes,mn.rwlocation,mn.usedmelassettag," +
	"mn.shipmenteta, mn.mel_accept, (select count(origid) from mel_inventory where parent_id=mn.origid) as qty " +
	"from mel_csgn mn ";

	switch(itype)
	{
		case 1: // by date range
			sqlstm += "where mn.datecreated between '" + sdate + " 00:00:00' and '" + edate + " 23:59:00'";
			break;
		case 2: // by partner location
			sqlstm += "where mn.rwlocation='" + loca + "'";
			break;
	}

	sqlstm += " order by mn.origid";

	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(21); newlb.setMold("paging");
	newlb.addEventListener("onSelect", csgnclkier);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "datecreated", "csgn", "mel_user", "shipmenteta", "rwlocation", "mstatus", "extranotes","qty","usedmelassettag", "mel_accept" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		ki = lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		if(d.get("mstatus").equals("CANCEL")) ki.setStyle("text-decoration: line-through;font-size:9px");
		kabom.clear();
	}
}

void reallySaveMEL_equiplist()
{
	// check for dups in prev uploaded csgn
	itms = csgnassets_lb.getItems().toArray();
	snm = matg = "";
	for(i=0; i<itms.length; i++)
	{
		kk = kiboo.replaceSingleQuotes(lbhand.getListcellItemLabel(itms[i],1));
		if(!kk.equals("")) snm += "'" + kk + "',";
		kk = kiboo.replaceSingleQuotes(lbhand.getListcellItemLabel(itms[i],2));
		if(!kk.equals("")) matg += "'" + kk + "',";
	}

	try
	{
		snm = snm.substring(0,snm.length()-1);
		matg = matg.substring(0,matg.length()-1);
	} catch (Exception e) { guihand.showMessageBox("ERR: Anomalies in equipments list.. Cannot SAVE!"); return; }

	//sqlstm = "select serial_no from mel_inventory where serial_no in (" + snm + ") or mel_asset in (" + matg + ");";


	sqlstm = "select mi.contract_no,mi.serial_no, mi.mel_asset, mc.csgn from mel_inventory mi " + 
	"left join mel_csgn mc on mi.parent_id=mc.origid where mi.serial_no in (" + snm + ") or mi.mel_asset in (" + matg + ");";

	r = sqlhand.gpSqlGetRows(sqlstm);
	if(r.size() > 0)
	{
		// alert only, but still allow to save 'em uploaded things : 14/08/2015: req by Nisha
		alert("ERR: Some of the equipments are already in our database. No duplicates allowed but we will go ahead and save them anyway.\n" + r);
		sendCsgn_Notif(7,glob_sel_csgn); // send notif email
	}

	sqlstm = "delete from mel_inventory where parent_id=" + glob_sel_csgn;
	sqlhand.gpSqlExecuter(sqlstm);
	itms = csgnassets_lb.getItems().toArray();
	String[] clm = new String[11];
	sqlstm = "";
	for(i=0; i<itms.length; i++)
	{
		for(x=0; x<11; x++)
		{
			clm[x] = kiboo.replaceSingleQuotes(lbhand.getListcellItemLabel(itms[i],x));
		}

		sqlstm += "insert into mel_inventory (parent_id,contract_no,serial_no,mel_asset,item_desc,item_type,brand_make,model,sub_type,sub_spec,hdd,ram) values (" +
		glob_sel_csgn + ",'" + clm[0] + "','" + clm[1] + "','" + clm[2] + "','" + clm[3] + "','" + clm[4] + "','" + clm[5] + "'," +
		"'" + clm[6] + "','" + clm[7] + "','" + clm[8] + "','" + clm[9] + "','" + clm[10] + "');";
	}
	sqlhand.gpSqlExecuter(sqlstm);
	guihand.showMessageBox("Equipments list saved into consignment: " + glob_sel_csgn);
}

void sendCsgn_Notif(int itype, String icsgn)
{
	r = getMELCSGN_rec(icsgn);
	if(r == null)
	{
		guihand.showMessageBox("ERR: send email notification failed - cannot retrieve consignment record.");
		return;
	}

	subj = topeople = msgtext = partn = "";
	mf = (r.get("usedmelassettag") == null) ? "NO" : ( (r.get("usedmelassettag")) ? "YES" : "NO");
	shipeta = (r.get("shipmenteta") == null) ? "UNDEFINED" : dtf2.format(r.get("shipmenteta"));

	extranotes = kiboo.checkNullString( r.get("extranotes") ) ;
	switch(itype)
	{
		case 5: // 13/08/2015: req nisha, send notif email when price quotes ready for MEL
			extranotes = "Quote Completed";
			break;

		case 6: // 13/08/2015: req nisha, send notif when audit-report ready for MEL
			extranotes = "Audit Report Completed";
			break;

		case 7: // 13/08/2015: req nisha, send notif if dups found in consignment upload
			extranotes = "Duplicates serial-numbers or asset-numbers, etc";
			break;
	}

	emsg =
	"------------------------------------------------------" +
	"\nMEL CSGN REF      : " + kiboo.checkNullString( r.get("csgn") ) +
	"\nETA               : " + shipeta +
	"\nStatus            : " + kiboo.checkNullString( r.get("mstatus") ) +
	"\nRW warehouse      : " + kiboo.checkNullString( r.get("rwlocation") ) +
	"\nQty               : " + glob_csgn_qty +
	"\nUse MEL asset-tag : " + mf +
	"\nNotes             : " + extranotes +
	( (mf.equals("YES")) ? "\n\n**ALERT** This consignment upload is using MEL asset-tags as serial-numbers." : "" ) +
	"\n\nPlease login to check and process ASAP." +
	"\n------------------------------------------------------";

	switch(itype)
	{
		case 1: // csgn commit notif
			subj = "[COMMITTED] MEL Consignment-note: " + icsgn + " (ETA:" + shipeta + ")";
			topeople = luhand.getLookups_ConvertToStr("MEL_RW_COORD",2,",") + "," + partn;
			break;

		case 2: // cancel notif
			subj = "[CANCELLED] MEL Consignment-note: " + icsgn;
			topeople = luhand.getLookups_ConvertToStr("MEL_RW_COORD",2,",") + "," + partn;
			break;

		case 3: // send test notif
			subj = "[TESTING] mel consignment-note (ETA:" + shipeta + ")";
			topeople = "victor@rentwise.com";
			break;

		case 4: // resend notification to partner defined in lookup MEL_SHAH_ALAM, MEL_KOTA_KINABALU, MEL_KUCHING
			subj = "[NOTIFICATION] MEL Consignment-note: " + icsgn;
			if(!lui.equals("MEL_"))
			{
				lui = "MEL_" + kiboo.checkNullString(r.get("rwlocation"));
				if(!lui.equals("MEL_")) // csgn got rwlocation, can get email addrs for partners
				{
					try
					{
						topeople = luhand.getLookups_ConvertToStr(lui,2,",");
						msgtext = "Sending notification email to partner..";
					} catch (Exception e)
					{
						topeople = "";
						msgtext = "ERR: cannot get partner email address";
					}
				}
			}
			else
				msgtext = "ERR: cannot send email, partner email address unavailable..";

			break;

		case 5: // 13/08/2015: req nisha, send notif email when price quotes ready for MEL
			subj = "[QUOTE COMPLETED] MEL Consignment-note: " + icsgn;
			topeople = luhand.getLookups_ConvertToStr("MEL_CONTACTS",2,",");
			break;

		case 6: // 13/08/2015: req nisha, send notif when audit-report ready for MEL
			subj = "[AUDIT REPORT COMPLETED] MEL Consignment-note: " + icsgn;
			topeople = luhand.getLookups_ConvertToStr("MEL_CONTACTS",2,",");
			break;

		case 7: // 13/08/2015: req nisha, send notif if dups found in consignment upload
			subj = "[DUPLICATES FOUND] MEL Consignment-note: " + icsgn;
			topeople = luhand.getLookups_ConvertToStr("MEL_CONTACTS",2,",");
			break;
	}
	if(!topeople.equals("")) gmail_sendEmail("", GMAIL_username, GMAIL_password, GMAIL_username, topeople, subj, emsg );
	if(!msgtext.equals("")) guihand.showMessageBox(msgtext);
}

