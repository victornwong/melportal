import org.victor.*;
// Funcs used in MEL_specUpdate_v1.zul. Knockoff and modif for MEL

item_row_counter = 1;

class tbnulldrop implements org.zkoss.zk.ui.event.EventListener
{	public void onEvent(Event event) throws UiException	{} }
textboxnulldrop = new tbnulldrop();

void toggButts_specupdate(boolean iwhat)
{
	Object[] kbb =
	{
		//mpftogcheck_b, mpfbutt, savespecs_b, getstkname_b, commitauditform_b,
		getstkname_b,mpfbutt,removeitem_b,savespecs_b,scanassettag_tb
	};
	for(i=0; i<kbb.length; i++)
	{
		kbb[i].setDisabled(iwhat);
	}
}

String getAssetTagsFromListbox()
{
	ret_assettags = "";
	if(adtitems_holder.getFellowIfAny("audititems_lb") == null) return "";
	if(audititems_lb.getItemCount() == 0) return "";

	jk = audititems_lb.getItems().toArray();
	for(i=0;i<jk.length;i++)
	{
		atg = lbhand.getListcellItemLabel(jk[i],0);
		if(!atg.equals("")) ret_assettags += "'" + atg + "',";
	}
	try { ret_assettags = ret_assettags.substring(0,ret_assettags.length()-1); return ret_assettags; } catch (Exception e) { return ""; }
}

String getAssetTagsFromGrid()
{
	ret_assettags = "";
	try
	{
		jk = grn_rows.getChildren().toArray();

		for(i=0;i<jk.length;i++)
		{
			ki = jk[i].getChildren().toArray();
			ret_assettags += "'" + ki[3].getValue() + "',";
		}
	} catch (Exception e) {}
	try { ret_assettags = ret_assettags.substring(0,ret_assettags.length()-1); return ret_assettags; } catch (Exception e) { return ""; }
}

void panel_Close() // main-panel onClose do something
{
	/*
	if(!glob_sel_audit.equals(""))
	{
		saveSpecs_listbox(glob_sel_audit);
	}
	*/
	/* if(!glob_sel_grn.equals("")) // if GRN selected - save 'em specs
	{	saveSpecs(); } */
}

org.zkoss.zul.Row makeItemRow_specup(Component irows, String iname, String iatg, String isn, String iqty, String irwstockname)
{
	String[] lookups_ref = { // refer to MEL_specUpdate_v1 -> specs_field_type
	"","","","","","", // 5
	"",
	"","","","MEL_ADT_LAPTOPSCREEN","", // 11
	"MEL_ADT_CASECOLOR","MEL_ADT_FORMFACTOR","","","", // 16
	"","MEL_ADT_MEDIADRIVES","","YESNO_DEF","YESNO_DEF", // 21
	"YESNO_DEF","YESNO_DEF", // 23

	"","","MEL_ADT_OPERABILITY", // 26
	"MEL_ADT_OPERABILITY", "MEL_ADT_OPERABILITY", "MEL_ADT_OPERABILITY", "MEL_ADT_OPERABILITY",

	"MEL_ADT_APPEARANCE","MEL_ADT_APPEARANCE","MEL_ADT_APPEARANCE","MEL_ADT_APPEARANCE","MEL_ADT_APPEARANCE",
	"MEL_ADT_COMPLETENESS","MEL_ADT_COMPLETENESS","MEL_ADT_COMPLETENESS","MEL_ADT_COMPLETENESS","MEL_ADT_COMPLETENESS",

	"MEL_ADT_GRADE","MEL_ADT_FORMFACTOR","MEL_ADT_CASECOLOR", // 31
	"MEL_ADT_LAPTOPSCREEN","MEL_ADT_HDDSIZE","MEL_ADT_RAMSIZE","MEL_ADT_RAMSTICKS","MEL_ADT_DIMMSLOT", // 36
	"MEL_ADT_OS","MEL_ADT_MEDIADRIVES","YESNO_DEF","YESNO_DEF","", // 41
	};

	k9 = "font-size:9px";
	nrw = new org.zkoss.zul.Row();
	nrw.setParent(irows);
	ngfun.gpMakeCheckbox(nrw,"",item_row_counter.toString(),k9);
	ngfun.gpMakeLabel(nrw,"",iname,k9); // item-name using label
	ngfun.gpMakeLabel(nrw,"",irwstockname,k9); // rw stockname using label

	ngfun.gpMakeLabel(nrw,"",iatg,k9);
	ngfun.gpMakeLabel(nrw,"",isn,k9);

	String[] kabom = new String[1];

	for(k=5;k<specs_field_type.length;k++)
	{
		/*
		if(specs_field_type[k].equals("lb"))
		{
			klb = new Listbox(); klb.setMold("select"); klb.setStyle(k9); klb.setParent(nrw);

			if(k == 5)
			{
				for(d : glob_focus6_grades)
				{
					kabom[0] = d.get("grade");
					if(kabom[0] != null) lbhand.insertListItems(klb,kabom,"false","");
				}
			}

			if(!lookups_ref[k].equals("")) luhand.populateListbox_ByLookup(klb, lookups_ref[k], 2);

			klb.setSelectedIndex(0);
		}
		else
			ngfun.gpMakeTextbox(nrw,"","",k9,"95%",textboxnulldrop);
		*/
		ngfun.gpMakeLabel(nrw,"","",k9);
	}
	item_row_counter++;
	return nrw;
}

void show_MELinventory(String iwhat) // get 'em recs from mel_inventory by melgrn_id
{
	if(glob_focus6_grades == null) glob_focus6_grades = getFocus_StockGrades(); // reload if null
	if(scanitems_holder.getFellowIfAny("grn_grid") != null) grn_grid.setParent(null);
	ngfun.checkMakeGrid(scanitems_colws, scanitems_collb, scanitems_holder, "grn_grid", "grn_rows", "", "", false);

	sqlstm = "select * from mel_inventory where melgrn_id=" + iwhat + " order by rw_assettag";
	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	itmc = 0;
	item_row_counter = 1; // reset item row-counter to 1 each time
	for(d : rcs)
	{
		nrw = makeItemRow_specup(grn_rows, d.get("item_desc"), d.get("rw_assettag"), d.get("serial_no"), "1", d.get("rw_stockname") );

		ki = nrw.getChildren().toArray();
		for(k=0;k<MEL_invt_fields.length;k++)
		{
			try
			{
				if(d.get(MEL_invt_fields[k]) != null)
				{
					cix = k + 5;
					if(ki[cix] instanceof Listbox)
					{
						lbhand.matchListboxItems(ki[cix], d.get(MEL_invt_fields[k]) );
					}
					else
						ki[cix].setValue( d.get(MEL_invt_fields[k]) );
				}
			} catch (java.lang.ArrayIndexOutOfBoundsException e) {}
		}

		itmc++;
	}
	melgrnitemcount_lbl.setValue("(Items loaded: " + itmc + ")");
}

void show_MELGRN_meta(String iwhat) // knockoff from MELGRN_funcs.zs but with modif to refer to mel_inventory
{
	melgrn_no.setValue("MELGRN: " + iwhat);
	/*
	r = getMELGRN_rec(iwhat); if(r != null)	{}
	*/
	toggButts_specupdate( (glob_sel_auditdate.equals("")) ? false : true );
	show_MELinventory(iwhat);
	workarea.setVisible(true);
}

Object[] melgrnhds =
{
	new listboxHeaderWidthObj("MELGRN",true,"60px"),
	new listboxHeaderWidthObj("DATED",true,"70px"),
	new listboxHeaderWidthObj("MEL REF",true,"90px"),
	new listboxHeaderWidthObj("CSGN",true,"70px"), // 3
	new listboxHeaderWidthObj("BATCH",true,"70px"),
	new listboxHeaderWidthObj("RWLOCA",true,"70px"),
	new listboxHeaderWidthObj("USER",true,""),
	new listboxHeaderWidthObj("STAT",true,"70px"), // 7
	new listboxHeaderWidthObj("UNKWN",true,""),
	new listboxHeaderWidthObj("COMMIT",true,""),
	new listboxHeaderWidthObj("C.User",true,""), // 10
	new listboxHeaderWidthObj("AUDIT",true,""),
	new listboxHeaderWidthObj("A.User",true,""),
	new listboxHeaderWidthObj("A.Id",true,""),
};
GRNSTAT_POS = 7;
CSGN_POS = 3;
BATCH_POS = 4;
UNKNOWN_POS = 8;
AUDITDATE_POS = 11;

class grnclicker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_sel_grn = lbhand.getListcellItemLabel(isel,0);
		glob_sel_stat = lbhand.getListcellItemLabel(isel,GRNSTAT_POS);
		glob_sel_parentcsgn = lbhand.getListcellItemLabel(isel,CSGN_POS);
		glob_sel_batchno = lbhand.getListcellItemLabel(isel,BATCH_POS);
		glob_sel_unknown = lbhand.getListcellItemLabel(isel,UNKNOWN_POS);
		glob_sel_auditdate = lbhand.getListcellItemLabel(isel,AUDITDATE_POS);

		show_MELGRN_meta(glob_sel_grn);

		//if(grn_show_meta) showGRN_meta(glob_sel_grn);
		//grn_Selected_Callback();
	}
}
grnclik = new grnclicker();

void show_MELGRN(int itype) // knockoff from MELGRN_funcs.zs
{
	last_showgrn_type = itype;
	sct = kiboo.replaceSingleQuotes(searhtxt_tb.getValue().trim());
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	jid = kiboo.replaceSingleQuotes(grnid_tb.getValue().trim());
	loca = p_location.getSelectedItem().getLabel();
	//batg = kiboo.replaceSingleQuotes( assettag_by.getValue().trim() );

	Listbox newlb = lbhand.makeVWListbox_Width(melgrnlb_holder, melgrnhds, "melgrn_lb", 3);

	sqlstm = "select mg.origid, mg.datecreated, mg.parent_csgn, mg.username, mg.gstatus, mg.rwlocation, mg.batch_no," +
	"mg.commitdate, mg.commituser, mg.auditdate, mg.audituser, mg.audit_id," +
	"(select csgn from mel_csgn where origid=mg.parent_csgn) as melref, case when unknown_snums is null then '' else 'YES' end as unknowns from mel_grn mg ";

	switch(itype)
	{
		case 1: // by date range and search-text if any
			sqlstm += "where mg.rwlocation='" + user_location + "' " +
			"and mg.datecreated between '" + sdate + " 00:00:00' and '" + edate + " 23:59:00' ";
			//if(!sct.equals(""))
			break;

		case 2: // by grn-id
			if(jid.equals("")) return;
			try { kk = Integer.parseInt(jid); } catch (Exception e) { return; }
			sqlstm += "where mg.rwlocation='" + user_location + "' and mg.origid=" + jid;
			break;

		case 3: // by RW location
			sqlstm += "where mg.rwlocation='" + loca + "' ";
			break;
	}

	sqlstm += showgrn_extra_sql + " order by mg.origid desc"; // showgrn_extra_sql defi in main

	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(10); newlb.setMold("paging");
	newlb.addEventListener("onSelect", grnclik);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid","datecreated","melref","parent_csgn","batch_no","rwlocation","username","gstatus","unknowns",
	"commitdate","commituser","auditdate","audituser","audit_id" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

// Save the specs into mel_inventory - will be injected back to FC6 once item-name matched
// d.get("item_desc"), d.get("rw_assettag"), d.get("serial_no")
boolean saveSpecs()
{
	RWITMNAME_POS = 2;
	SNUM_POS = 4;
	sqlstm = "";
	try
	{
		jk = grn_rows.getChildren().toArray();
		for(i=0;i<jk.length;i++)
		{
			ki = jk[i].getChildren().toArray();
			itm = kiboo.replaceSingleQuotes( ki[RWITMNAME_POS].getValue().trim() ); // to save if user matches MEL against FC6 item-name
			snm = kiboo.replaceSingleQuotes( ki[SNUM_POS].getValue().trim() );
			sx = ct = "";

			for(k=0; k<MEL_invt_fields.length;k++)
			{
				cix = k + 5; // offset

				if(ki[cix] instanceof Listbox)
					ct = ki[cix].getSelectedItem().getLabel();
				else
					ct = kiboo.replaceSingleQuotes( ki[cix].getValue().trim() );

				sx += MEL_invt_fields[k] + "='" + ct + "',";
			}
			try { sx = sx.substring(0,sx.length()-1); } catch (Exception e) {}

			sqlstm += "update mel_inventory set rw_stockname='" + itm + "'," + sx +
			" where serial_no='" + snm + "' and melgrn_id=" + glob_sel_grn + ";";
		}
	} catch (Exception e) { return false; }

	sqlhand.gpSqlExecuter(sqlstm);
	return true;
}

void showCheckstock_win(Div idiv) // knockoff from jobsheet_funcs.zs but modified
{
	Object[] cstkhds1 =
	{
		new listboxHeaderWidthObj("No.",true,"40px"),
		new listboxHeaderWidthObj("Items found",true,""),
		new listboxHeaderWidthObj("Type",true,"40px"),
	};
	String[] fl_t1 = { "name", "item" };

	kn = kiboo.replaceSingleQuotes( chkstkname_tb.getValue().trim() );
	if(kn.equals("")) return;

	Listbox newlb = lbhand.makeVWListbox_Width(idiv, cstkhds1, "chkstock_lb", 3);

	csqlstm = "select distinct name,item from partsall_0 " +
	"where name like '%" + kn + "%' group by name,item order by item,name";

	r = sqlhand.rws_gpSqlGetRows(csqlstm);
	if(r.size() == 0) return;
	newlb.setMold("paging"); newlb.setRows(20);
	ArrayList kabom = new ArrayList();
	lnc = 1;
	for(d : r)
	{
		kabom.add(lnc.toString() + "." );
		ngfun.popuListitems_Data(kabom,fl_t1,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
		lnc++;
	}

	if(checkitems_doubleclicker != null) // set double-cliker if available
		lbhand.setDoubleClick_ListItems(newlb, checkitems_doubleclicker);
}

// Generate MEL audit-report from Harvin final template 02/02/2015
// 11/03/2015: modif to either get mel_inventory by melgrn_id or audit_id
void exportMELAuditForm(String iwhat, int itype)
{
	sqlstm = "select * from mel_inventory "; 
	switch(itype)
	{
		case 1: // by parent_id = mel_csgn.origid
			//saveSpecs(); // save latest before audit-form generation
			sqlstm += " where parent_id=" + iwhat;
			break;
		case 2: // by audit_id
			saveSpecs_listbox(iwhat); // mel_specupdate_lb.zs
			sqlstm += " where audit_id=" + iwhat;
			break;
	}
	sqlstm += " order by rw_assettag";
	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0)
	{
		guihand.showMessageBox("ERR: no audit details found..");
		return;
	}
	itemcount = rowcount = 1;

	templatefn = "rwimg/MELAUDITFORM_v1.xls";
	inpfn = session.getWebApp().getRealPath(templatefn);
	InputStream inp = new FileInputStream(inpfn);
	HSSFWorkbook excelWB = new HSSFWorkbook(inp);
	evaluator = excelWB.getCreationHelper().createFormulaEvaluator();
	HSSFSheet sheet = excelWB.getSheetAt(0);
	//HSSFSheet sheet = excelWB.createSheet("THINGS");

	Font wfont = excelWB.createFont(); wfont.setFontHeightInPoints((short)8); wfont.setFontName("Arial");

	CellStyle tcellstyle =  excelWB.createCellStyle();
	tcellstyle.setAlignment(CellStyle.ALIGN_CENTER); tcellstyle.setVerticalAlignment(CellStyle.VERTICAL_CENTER);
	tcellstyle.setFont(wfont); tcellstyle.setBorderLeft(CellStyle.BORDER_THIN);
	tcellstyle.setBorderRight(CellStyle.BORDER_THIN); tcellstyle.setBorderTop(CellStyle.BORDER_THIN); tcellstyle.setBorderBottom(CellStyle.BORDER_THIN);
	
	CellStyle pistyle =  excelWB.createCellStyle(); pistyle.cloneStyleFrom(tcellstyle); pistyle.setAlignment(CellStyle.ALIGN_LEFT); pistyle.setWrapText(true);

	String[] meladtfields = { // as defined by Harvin 02/02/2015
		"contract_no", // Contract
		"batch_no", // Batch no
		"serial_no", // Serial no
		"mel_asset", // Asset Tag (MEL Ref)
		"brand_make", // Brand
		"model", // Model
		"sub_type", // Processor type / Monitor size
		"sub_spec", // Processor speed / Monitor type
		"m_barcode", // Barcode
		"m_notes", // Notes
		"m_operability", // Operability
		"m_appearance", // Appearance
		"m_completeness", // Completeness
		"m_grade", // Grade
		"m_formfactor", // Form Factor (Adapter)
		"m_casecolor", // Case Colour
		"m_laptopscreensize", // Laptop screen size
		"m_hddsize", // HDD size  / Connection Type
		"m_ramsize", // RAM Size & Specs
		"m_ramsticks", // RAM STICKS
		"m_mediadrives", // Media Drives
		"m_os", // OS Licence
		"m_hddwiped", // HDD Wiped
		"m_hdddestroyed", // HDD Destroyed
		"m_hdddestsnum", // If destroyed, HDD Serial Number
	};

	for(d : rcs)
	{
		excelInsertString(sheet,rowcount,0,itemcount.toString()); // Item No
		for(i=0; i<meladtfields.length; i++)
		{
			kk = "";
			if( meladtfields[i].equals("m_operability") ) // concatenate the 5 columns in db. Pretty ugly coding
			{
				kk += kiboo.checkNullString(d.get("m_operability"));

				ck = kiboo.checkNullString(d.get("m_operability2"));
				if( !ck.equals("") && !ck.equals("TESTED_OK") ) kk += ", " + ck;

				ck = kiboo.checkNullString(d.get("m_operability3"));
				if( !ck.equals("") && !ck.equals("TESTED_OK") ) kk += ", " + ck;

				ck = kiboo.checkNullString(d.get("m_operability4"));
				if( !ck.equals("") && !ck.equals("TESTED_OK") ) kk += ", " + ck;

				ck = kiboo.checkNullString(d.get("m_operability5"));
				if( !ck.equals("") && !ck.equals("TESTED_OK") ) kk += ", " + ck;
			}
			else
			if( meladtfields[i].equals("m_appearance") )
			{
				kk += kiboo.checkNullString(d.get("m_appearance"));

				ck = kiboo.checkNullString(d.get("m_appearance2"));
				if( !ck.equals("") && !ck.equals("GOOD") ) kk += ", " + ck;

				ck = kiboo.checkNullString(d.get("m_appearance3"));
				if( !ck.equals("") && !ck.equals("GOOD") ) kk += ", " + ck;

				ck = kiboo.checkNullString(d.get("m_appearance4"));
				if( !ck.equals("") && !ck.equals("GOOD") ) kk += ", " + ck;

				ck = kiboo.checkNullString(d.get("m_appearance5"));
				if( !ck.equals("") && !ck.equals("GOOD") ) kk += ", " + ck;
			}
			else
			if( meladtfields[i].equals("m_completeness") )
			{
				kk += kiboo.checkNullString(d.get("m_completeness"));

				ck = kiboo.checkNullString(d.get("m_completeness2"));
				if( !ck.equals("") && !ck.equals("COMPLETE") ) kk += ", " + ck ;

				ck = kiboo.checkNullString(d.get("m_completeness3"));
				if( !ck.equals("") && !ck.equals("COMPLETE") ) kk += ", " + ck ;

				ck = kiboo.checkNullString(d.get("m_completeness4"));
				if( !ck.equals("") && !ck.equals("COMPLETE") ) kk += ", " + ck ;

				ck = kiboo.checkNullString(d.get("m_completeness5"));
				if( !ck.equals("") && !ck.equals("COMPLETE") ) kk += ", " + ck ;
			}
			else
			{
				kk = kiboo.checkNullString( d.get(meladtfields[i]) );
			}

			excelInsertString(sheet,rowcount,i+1,kk);
		}
		itemcount++;
		rowcount++;
	}

	tfname = "MELAUDITFORM_MELGRN_" + iwhat + ".xls";
	outfn = session.getWebApp().getRealPath("tmp/" + tfname );
	FileOutputStream fileOut = new FileOutputStream(outfn);
	excelWB.write(fileOut);
	fileOut.close();
	downloadFile(kasiexport,tfname,outfn);
}

void notifyCommit_MELAUDIT(String iwhat)
{
	if(iwhat.equals("")) return;
	subj = topeople = emsg = "";
	/*
	r = getMELGRN_rec(iwhat);
	if(r == null) return;

	subj = "[COMMIT AUDIT-FORM] MELGRN: " + iwhat + " at " + r.get("rwlocation");
	topeople = luhand.getLookups_ConvertToStr("MEL_RW_COORD",2,",");
	emsg =
	"------------------------------------------------------" +
	"\nMELGRN          : " + iwhat +
	"\nRW warehouse    : " + r.get("rwlocation") +
	"\n\nPlease login to post specs-update and Focus GRN" +
	"\n------------------------------------------------------";

	gmail_sendEmail("", GMAIL_username, GMAIL_password, GMAIL_username, topeople, subj, emsg );
	*/
}
