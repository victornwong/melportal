import org.victor.*;
// MEL-GRN general funcs

RECEIVED_SERIALS_STYLE = "background:#2E60CE;font-size:9px;color:#ffffff";
UNKNOWN_SERIALS_STYLE = "background:#DD1FD4;font-size:9px;color:#ffffff";
DUPS_SERIALS_STYLE = "background:#E9E415;font-size:9px;";

void toggButts(boolean iwhat)
{
	// notifprob_b
	Object[] bb = { saveimpd_b, rediginvt_b, savemelgrn_b, impsnums_b, admdelequip_b };
	for(i=0;i<bb.length;i++)
	{
		bb[i].setDisabled(iwhat);
	}
}

// Get equips count from snums stored in mel_grn.serial_numbers
int getEquipCount_fromSerials(Object intext)
{
	ect = 0;
	try // get number of equips from snums
	{
		k = sqlhand.clobToString(intext).split("\n");
		ect = k.length;
	} catch (Exception e) {}
	return ect;
}

// iwhat: mel-csgn id
int getEquipCount_fromMELCSGN(int iwhat)
{
	retval = 0;
	sqlstm = "select count(origid) as icnt from mel_inventory where parent_id=" + iwhat;
	r = sqlhand.gpSqlFirstRow(sqlstm);
	if(r != null) retval = r.get("icnt");
	return retval;
}

void populate_MELCSGN(Listbox ilb)
{
	kk = ilb.getItems().toArray();
	for(i=0;i<kk.length;i++) // remove prev items
	{
		kk[i].setParent(null);
	}

	//sqlstm = "select distinct csgn,origid from mel_csgn where rwlocation='" + user_location + "' and csgn<>'UNDEF' and mstatus='COMMIT';";
	sqlstm = "select distinct csgn,origid from mel_csgn where csgn<>'UNDEF' and mstatus='COMMIT';"; // 17/02/2016: show all consignment, no check on location
	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	String[] sta = new String[2];
	for(d : rcs)
	{
		sta[0] = kiboo.checkNullString(d.get("csgn"));
		sta[1] = d.get("origid").toString();
		lbhand.insertListItems(ilb,sta,"false","");
	}
	ilb.setSelectedIndex(0); // defa select item 1
}

void showMELCSGN_itemcount(int imelcsgn)
{
	kk = getEquipCount_fromMELCSGN(imelcsgn);
	k_itemcount_lbl.setValue("(CSGN item count: " + kk.toString() + ")");
}

void show_MELGRN_meta(String iwhat)
{
	melgrn_no.setValue("MELGRN: " + iwhat);
	k_howmanyscan_lbl.setValue("");

	xm_batch_no.setValue("");
	populate_MELCSGN(xm_csgn); // refresh csgn drop-box

	if( impsns_holder.getFellowIfAny("impsn_lb") != null) impsn_lb.setParent(null); // always remove

	r = getMELGRN_rec(iwhat);
	if(r != null)
	{
		knums = atgs = "";
		if(r.get("parent_csgn") != null)
		{
			lbhand.matchListboxItemsColumn(xm_csgn, r.get("parent_csgn").toString(),1);
			showMELCSGN_itemcount(r.get("parent_csgn"));
		}

		glob_sel_batchno = kiboo.checkNullString(r.get("batch_no")); // save for later use
		xm_batch_no.setValue(glob_sel_batchno);

		if(r.get("serial_numbers") != null) knums = sqlhand.clobToString(r.get("serial_numbers"));
		if(r.get("unknown_snums") != null) knums += sqlhand.clobToString(r.get("unknown_snums"));
		if(r.get("rw_asset_tags") != null) atgs = sqlhand.clobToString(r.get("rw_asset_tags"));
		if(!knums.equals(""))
		{
			iks = "";
			isn = knums.split("\n");
			iatg = atgs.split("\n");
			for(i=0; i<isn.length; i++)
			{
				th = "---";
				try { th = iatg[i]; } catch (Exception e) {}
				iks += th + "\n" + isn[i] + "\n"; // req by lamos - scan asset-tag first then s/num
			}
			importParse_MEL_snums(iks,"");
		}

		toggButts( r.get("gstatus").equals("DRAFT") ? false : true);
	}
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
	new listboxHeaderWidthObj("C.User",true,""),
	new listboxHeaderWidthObj("AUDIT",true,""),
	new listboxHeaderWidthObj("A.User",true,""),
	new listboxHeaderWidthObj("A.Id",true,""),
};
GRNSTAT_POS = 7;
CSGN_POS = 3;
BATCH_POS = 4;
UNKNOWN_POS = 8;

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

		show_MELGRN_meta(glob_sel_grn);

		//if(grn_show_meta) showGRN_meta(glob_sel_grn);
		//grn_Selected_Callback();
	}
}
grnclik = new grnclicker();

// user_location defi in main file - global
void show_MELGRN(int itype)
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

	sqlstm += " order by mg.origid desc";
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

Object[] csgnasshd = // knockoff csgnFuncs.zs
{
	new listboxHeaderWidthObj("No.",true,"50px"),
	new listboxHeaderWidthObj("Serial Number",true,""),
	new listboxHeaderWidthObj("RW AssTag",true,""),
	new listboxHeaderWidthObj("CSGN",true,""), // 3
	new listboxHeaderWidthObj("Contract #",true,""),
	new listboxHeaderWidthObj("Asset Number (MEL Ref)",true,""),
	new listboxHeaderWidthObj("MEL Item",true,""), // 6
	new listboxHeaderWidthObj("Asset Category",true,""),
	new listboxHeaderWidthObj("Make",true,""),
	new listboxHeaderWidthObj("Model",true,""),
	new listboxHeaderWidthObj("Processor Or Monitor Type",true,""),
	new listboxHeaderWidthObj("Processor Speed Or Monitor Size",true,""), // 11
	new listboxHeaderWidthObj("HDD Size",true,""),
	new listboxHeaderWidthObj("RAM",true,""),
	new listboxHeaderWidthObj("MELGRN",true,""),
	new listboxHeaderWidthObj("Recv",true,""), // 15
};

// Parse the serial-numbers scanned and sumbat
// isn=the MEL serial-numbers, icsgn=unused at the moment, thought want to match against inventory the parent_csgn
// 23/01/2015: req from lamos, scan asstag first then s/num
// 28/09/2015: check dups inside listbox ONLY requested by harvin/lai/satish - higlite different color
void importParse_MEL_snums(String isn, String icsgn)
{
	if(glob_sel_parentcsgn.equals("")) { guihand.showMessageBox("ERR: please tie MELGRN to MEL REF before parsing serial-numbers.."); return; }
	kns = isn.split("\n");
	if(kns.length == 0) { guihand.showMessageBox("ERR: invalid serial-numbers"); return; }

	Listbox newlb = lbhand.makeVWListbox_Width(impsns_holder, csgnasshd, "impsn_lb", 21);
	newlb.setMultiple(true);

	ArrayList kabom = new ArrayList();
	HashMap hm = new HashMap(); // check for dups s/nums
	scancount = 0;

	String[] fl = { "parent_id","contract_no","mel_asset","item_desc","item_type",
	"brand_make","model","sub_type","sub_spec","hdd","ram","melgrn_id","received" };

	for(i=0; i<kns.length; i++)
	{
		try
		{
			if(!hm.containsKey(kns[i+1])) // make sure no dups
			{
				sty = "";
				kabom.add((scancount+1).toString() + "."); // 03/09/2015: numbering

				kabom.add(kns[i+1]);
				kabom.add(kns[i]);

				// get rec from mel_inventory
				sqlstm = "select * from mel_inventory where serial_no='" + kns[i+1].trim() + "';";
				ir = sqlhand.gpSqlFirstRow(sqlstm);
				if(ir != null)
				{
					ngfun.popuListitems_Data(kabom,fl,ir);
					if(ir.get("received") != null) // equip already received earlier
					{
						sty = RECEIVED_SERIALS_STYLE;
					}
					unknownt = ir.get("unknown");
					if(unknownt != null)
					{
						sty = (unknownt) ? UNKNOWN_SERIALS_STYLE : "";
					}
				}
				else
				{
					for(n=0;n<fl.length-1;n++)
					{
						kabom.add("---");
					}
					kabom.add(""); // the received-date colm
					sty = ""; //background:#CC2F2F;font-size:9px;color:#ffffff
				}

				lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false",sty);
				kabom.clear();
				hm.put(kns[i+1],1);
				scancount++;
			}
			else
			{
				//newlb.setParent(null); // remove listbox if dups found!!
				//guihand.showMessageBox("ERR: duplicate serial-number found : " + kns[i+1]);
				//return;
			}
			i++;
		} catch (Exception e) {}
	}
	k_howmanyscan_lbl.setValue("Parsed: " + scancount.toString() + " item(s)");

	// 28/09/2015: check within listbox ONLY for dups
	checkImportParse_serials();
}

// Check import/parse duplicate serial/asset-tags
void checkImportParse_serials()
{
	newlb = impsns_holder.getFellowIfAny("impsn_lb");
	if(newlb == null) { alert("nothing.."); return; }

	HashMap lbc = new HashMap();
	ts = newlb.getItems().toArray();
	//alert(newlb + " :: " + ts.length);
	kk = "";
	for(i=0;i<ts.length;i++)
	{
		hilite = "";
		d1 = lbhand.getListcellItemLabel(ts[i],1);
		if(!lbc.containsKey(d1)) lbc.put(d1,1);
		else { hilite = DUPS_SERIALS_STYLE; kk += "dups found: " + d1 + "\n"; }
		d2 = lbhand.getListcellItemLabel(ts[i],2);
		if(!lbc.containsKey(d2)) lbc.put(d2,1);
		else { hilite = DUPS_SERIALS_STYLE; kk += "dups found: " + d2 + "\n"; }

		if(!hilite.equals("")) ts[i].setStyle(hilite);
		//kk += "d1: " + d1 + " d2: " + d2 + "\n";
	}
	//alert(lbc);
	//debuglabel.setValue(kk);
}

void updateMEL_inventory(String igrn, String ibn)
{
	ki = impsn_lb.getItems().toArray();
	ArrayList sn_notin_inventory = new ArrayList();
	todaydate =  kiboo.todayISODateTimeString();
	shwdate = kiboo.todayISODateString();
	sqlstm = snums = satgs = "";

	dbg = "";

	for(i=0; i<ki.length; i++)
	{
		xastg = lbhand.getListcellItemLabel(ki[i],PARSE_ASSETTAG_POS); // asset-tag
		xsn = lbhand.getListcellItemLabel(ki[i],PARSE_SNUM_POS); // serial-no
		xcsgn = lbhand.getListcellItemLabel(ki[i],PARSE_CSGN_NO_POS); // csgn no.
		xdr = lbhand.getListcellItemLabel(ki[i],PARSE_DATERECEIVED_POS); // date equip recv

		if(xcsgn.equals("---")) // equip not found in any csgn, save to later notify whoever
		{
			// 09/10/2015: req Harvin, just tie unknown serial from unknown consignment to current selected GRN's consignment
			// 09/12/2015: check serial-no exist in mel_inventory, don't insert
			injsql =
			"if not exists (select 1 from mel_inventory where serial_no='" + xsn + "') " +
			"begin " +
			"insert into mel_inventory (parent_id,serial_no) values (" + glob_sel_parentcsgn + ",'" + xsn + "'); " +
			"end;";

			sqlhand.gpSqlExecuter(injsql);
			sn_notin_inventory.add(xsn);
		}

		/* 07/09/2015: take out this control logic - Lai req to allow everything through
		if(!xdr.equals("")) // if equip already received earlier - problem!!
		{
			guihand.showMessageBox("ERR: some equipment(s) already being received earlier. Cannot proceed");
			return;
		}
		*/
		//dbg += xsn + " :: " + xastg + "\n";
		snums += xsn + "\n";
		satgs += xastg + "\n";

		sqlstm += "update mel_inventory set batch_no='" + ibn + "', rw_assettag='" + xastg + "', melgrn_id=" + igrn +
		" where serial_no='" + xsn + "';"; // and parent_id=" + xcsgn + ";";

		//lbhand.setListcellItemLabel(ki[i],PARSE_DATERECEIVED_POS,shwdate); // show recv date -used when commit GRN later
	}
	sqlstm += "update mel_grn set serial_numbers='" + snums + "', rw_asset_tags='" + satgs + "' where origid=" + igrn + ";";

	if(sn_notin_inventory.size() > 0) // some unknown snums found -- save 'em into grn-rec and send notif
	{
		pb = "";
		xk = sn_notin_inventory.toArray();
		for(x=0;x<xk.length;x++)
		{
			pb += xk[x] + "\n";
		}
		sqlstm += "update mel_grn set unknown_snums='" + pb + "' where origid=" + igrn;
		//notifyUnknownSerials(igrn); // send email notif
	}
	else
		sqlstm += "update mel_grn set unknown_snums=null where origid=" + igrn;

	if(!sqlstm.equals(""))
	{
		sqlhand.gpSqlExecuter(sqlstm);
		guihand.showMessageBox("Serial-numbers saved into database..");
	}
}

// Commit equips inventory link to csgn and batchno. set received date too
String commit_GRN_equips(String igrn, String ibn)
{
	if( impsns_holder.getFellowIfAny("impsn_lb") == null) return "";
	ki = impsn_lb.getItems().toArray();
	todaydate =  kiboo.todayISODateTimeString();
	shwdate = kiboo.todayISODateString();
	retsql = "";
	for(i=0; i<ki.length; i++)
	{
		xsn = lbhand.getListcellItemLabel(ki[i],PARSE_SNUM_POS); // serial-no
		xcsgn = lbhand.getListcellItemLabel(ki[i],PARSE_CSGN_NO_POS); // csgn no.
		if(!xcsgn.equals("---"))
		{
			retsql += "update mel_inventory set batch_no='" + ibn + "', melgrn_id=" + igrn + ", received='" + todaydate + "'" +
			" where serial_no='" + xsn + "' and parent_id=" + xcsgn + ";";
		}
	}
	return retsql;
}

/**
 * 07/09/2015: some modif to use mel_inventory.unknown flag instead of mel_grn.unknown_snums
 * @param iwhat MEL-grn origid
 */
void notifyUnknownSerials(String iwhat)
{
	if(iwhat.equals("")) return;
	subj = topeople = emsg = "";

	r = getMELGRN_rec(iwhat);
	if(r == null) return;
	/*
	if(r.get("unknown_snums") == null)
	{
		guihand.showMessageBox("ERR: no unknown serial-numbers in record..");
		return;
	}
	*/
	// 07/09/2015: get unknown serial-numbers by mel_inventory.unknown flag
	prntcsgn = r.get("parent_csgn").toString();
	sqlstm = "select serial_no from mel_inventory where parent_id=" + prntcsgn + " and unknown=1;";
	uks = sqlhand.gpSqlGetRows(sqlstm);
	if(uks.size() == 0) // no unknowns, show msg and return
	{
		guihand.showMessageBox("No unknown serial-numbers found..");
		return; 
	}
	unknowns = "";
	for(d : uks)
	{
		unknowns += d.get("serial_no") + "\n";
	}

	subj = "[UNKNOWN] Serial-numbers detected in MELGRN: " + iwhat + " at " + r.get("rwlocation");
	topeople = luhand.getLookups_ConvertToStr("MEL_RW_COORD",2,",");
	emsg =
	"------------------------------------------------------" +
	"\nMELGRN          : " + iwhat +
	"\nRW warehouse    : " + r.get("rwlocation") +
	"\nUnknown serials :\n\n" +
	//sqlhand.clobToString(r.get("unknown_snums")) +
	unknowns +
	"\n\nPlease login to check and process ASAP." +
	"\n------------------------------------------------------";

	gmail_sendEmail("", GMAIL_username, GMAIL_password, GMAIL_username, topeople, subj, emsg );
	add_RWAuditLog(JN_linkcode(),"", "Send unknown serials notification email", useraccessobj.username);
	guihand.showMessageBox("Notification email sent for unknown serial-numbers detected..");
}

void notifyCommitMELGRN(String iwhat)
{
	if(iwhat.equals("")) return;
	subj = topeople = emsg = "";
	r = getMELGRN_rec(iwhat);
	if(r == null) return;

	csgname = xm_csgn.getSelectedItem().getLabel();
	csgnitm = getEquipCount_fromMELCSGN( r.get("parent_csgn"));
	ec = getEquipCount_fromSerials( r.get("serial_numbers") );
	subj = "[COMMIT] MELGRN: " + iwhat + " at " + r.get("rwlocation");

	topeople = "victor@rentwise.com";
	if(!TESTING_MODE) topeople = luhand.getLookups_ConvertToStr("MEL_RW_COORD",2,",");
	emsg =
	"------------------------------------------------------" +
	"\nMEL REF         : " + csgname +
	"\nEquips count    : " + csgnitm.toString() +
	"\n------------------------------------------------------" +
	"\nMELGRN          : " + iwhat +
	"\nRW warehouse    : " + r.get("rwlocation") +
	"\nEquips received : " + ec.toString() +
	"\nNotes           : Goods Receive Phase" +
	"\n\nPlease login to check and process ASAP." +
	"\n------------------------------------------------------";

	gmail_sendEmail("", GMAIL_username, GMAIL_password, GMAIL_username, topeople, subj, emsg );
	add_RWAuditLog(JN_linkcode(),"", "Commit MELGRN and sent notification email", useraccessobj.username);
	guihand.showMessageBox("Committal notification email sent..");
}

/**
 * Inject unknown serial-numbers captured. Uses rec obj from mel_grn
 * @param igr mel_grn rec obj retrieved by caller
 */
String injectUnknownSerialNumbers(Object igr)
{
	// check parent_csgn assigned
	if(igr.get("parent_csgn") == null)
	{
		return "ERR: this MELGRN is not link to CSGN..cannot proceed";
	}

	prntcsgn  = igr.get("parent_csgn").toString();

	knums = atgs = "";
	todaydate =  kiboo.todayISODateTimeString();
	if(igr.get("serial_numbers") != null) knums = sqlhand.clobToString(igr.get("serial_numbers"));
	if(igr.get("unknown_snums") != null) knums += sqlhand.clobToString(igr.get("unknown_snums"));
	if(igr.get("rw_asset_tags") != null) atgs = sqlhand.clobToString(igr.get("rw_asset_tags"));

	if(!knums.equals(""))
	{
		iks = sqlstm = "";
		isn = knums.split("\n");
		iatg = atgs.split("\n");
		for(i=0; i<isn.length; i++) // store 'em snums and ass-tags into map
		{
			try
			{
				//if(TESTING_MODE) debuglabel.setValue(debuglabel.getValue() + "\nsn: " + isn[i] + " atg: " + iatg[i]);
				sqlstm += "if not exists(select 1 from mel_inventory where rw_assettag='" + iatg[i] + "') " +
					"begin " +
					"insert into mel_inventory (parent_id,serial_no,rw_assettag,received,unknown) values " +
					"(" + prntcsgn + ",'" + isn[i] + "','" + iatg[i] + "','" + todaydate + "',1)" +
					"end;";
			} catch (Exception e) {}
		}
		sqlhand.gpSqlExecuter(sqlstm);
	}
	else
		return "ERR: no serial-numbers or asset-tags to process.";

	return ""; // everything good - return empty string
}
