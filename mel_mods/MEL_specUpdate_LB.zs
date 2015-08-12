import org.victor.*;
// MEL specs-update using listbox instead of grid, all data entry through a popup

	String[] audititems_lb_fl = { "rw_assettag","serial_no","item_desc","rw_stockname",
	"rw_grade","brand_make","item_type","model","sub_type",
	"sub_spec","rw_monitortype","rw_color","rw_casing","rw_COA","rw_COA2","ram","hdd","rw_cdrom1","rw_comment",
	"rw_webcamyh","rw_bluetoothyh","rw_fingerprintyh","rw_cardreaderyh",
	"m_barcode","m_notes",
	"m_operability","m_operability2","m_operability3","m_operability4","m_operability5",
	"m_appearance","m_appearance2","m_appearance3","m_appearance4","m_appearance5",
	"m_completeness","m_completeness2","m_completeness3","m_completeness4","m_completeness5",
	"m_grade","m_formfactor","m_casecolor","m_laptopscreensize","m_hddsize","m_ramsize","m_ramsticks","m_dimmslot",
	"m_os","m_mediadrives","m_hddwiped","m_hdddestroyed","m_hdddestsnum"
	};

// Refresh 'em row counts in the audit items listbox
void refresh_Items_rowcount()
{
	if(adtitems_holder.getFellowIfAny("audititems_lb") == null) return;
	jk = audititems_lb.getItems().toArray();
	for(i=0; i<jk.length; i++)
	{
		lbhand.setListcellItemLabel(jk[i],0, (i+1).toString() + "." );
	}
}

// Knockoff from mel_specupdate_funcs.zs
void saveSpecs_listbox(String iadt)
{
	if(adtitems_holder.getFellowIfAny("audititems_lb") == null) return;
	if(audititems_lb.getItemCount() == 0) return;
	sqlstm = "";

	jk = audititems_lb.getItems().toArray();
	for(i=0; i<jk.length; i++)
	{
		itm = lbhand.getListcellItemLabel(jk[i],4); // refer to mel_specupdate_lb.adtitemshds
		snm = lbhand.getListcellItemLabel(jk[i],2);
		sx = ct = "";
		for(k=0; k<MEL_invt_fields.length;k++)
		{
			cix = k + ITEMS_OFFSET; // offset to listitem column
			ct = lbhand.getListcellItemLabel(jk[i],cix);
			sx += MEL_invt_fields[k] + "='" + ct + "',";
		}
		try { sx = sx.substring(0,sx.length()-1); } catch (Exception e) {}

		sqlstm += "update mel_inventory set rw_stockname='" + itm + "',audit_id=" + iadt + "," + sx +
		" where serial_no='" + snm + "';";
	}
	sqlhand.gpSqlExecuter(sqlstm);
	//guihand.showMessageBox("Specs saved..");
}

void showMELADT_meta(String iwhat)
{
	workarea.setVisible(true);
	meladt_header.setValue("MELADT: " + iwhat);
	toggButts_specupdate( (glob_sel_stat.equals("COMMIT")) ? true : false );

	newlb = lbhand.makeVWListbox_Width(adtitems_holder, adtitemshds, "audititems_lb", 20);
	newlb.setMultiple(true); newlb.setCheckmark(true);

	sqlstm = "select * from mel_inventory where audit_id=" + iwhat + " order by rw_assettag";
	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() != 0)
	{
		ArrayList kabom = new ArrayList();
		for(d : rcs) // show 'em mel_inventory items with audit_id linked
		{
			kabom.add("999"); // row count
			ngfun.popuListitems_Data(kabom,audititems_lb_fl,d);
			lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
			kabom.clear();
		}
		refresh_Items_rowcount();
	}

	show_CSGNAudit_itemcount(glob_sel_parentcsgn);
	fillDocumentsList(documents_holder,MELAUDIT_PREFIX,iwhat);
}

Object[] melaudithds =
{
	new listboxHeaderWidthObj("MELADT",true,"60px"),
	new listboxHeaderWidthObj("DATED",true,"70px"),
	new listboxHeaderWidthObj("MELREF",true,"90px"),
	new listboxHeaderWidthObj("CSGN",true,"70px"),
	new listboxHeaderWidthObj("USER",true,"80px"),
	new listboxHeaderWidthObj("STAT",true,"70px"), // 5
	new listboxHeaderWidthObj("AUDIT",true,"70px"),
	new listboxHeaderWidthObj("T.GRN",true,"70px"),
	new listboxHeaderWidthObj("REMARKS",true,""),
};
CSGN_POS = 3;
ADTSTAT_POS = 5;
TGRN_POS = 7;

class auditcliker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_sel_audit = lbhand.getListcellItemLabel(isel,0);
		glob_sel_parentcsgn = lbhand.getListcellItemLabel(isel,CSGN_POS);
		glob_sel_stat = lbhand.getListcellItemLabel(isel,ADTSTAT_POS);
		glob_sel_tempgrn = lbhand.getListcellItemLabel(isel,TGRN_POS);
		showMELADT_meta(glob_sel_audit);
	}
}
auditclik = new auditcliker();

void list_MELAUDIT(int itype)
{
	last_showaudit_type = itype;
	sct = kiboo.replaceSingleQuotes(searhtxt_tb.getValue().trim());
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	jid = kiboo.replaceSingleQuotes(grnid_tb.getValue().trim());
	loca = p_location.getSelectedItem().getLabel();
	//batg = kiboo.replaceSingleQuotes( assettag_by.getValue().trim() );

	Listbox newlb = lbhand.makeVWListbox_Width(melauditlb_holder, melaudithds, "melaudit_lb", 3);

	sqlstm = "select *,(select csgn from mel_csgn where madt.parent_csgn = origid) as melref from mel_audit madt ";

	switch(itype)
	{
		case 1: // by date range
			sqlstm += "where madt.datecreated between '" + sdate + " 00:00:00' and '" + edate + " 23:59:00'";
			break;

		case 2: // by meladt
			if(jid.equals("")) return;
			try { nn = Integer.parseInt(jid); } catch (Exception e) { return; }
			sqlstm += "where madt.origid=" + jid;
			break;
	}
	sqlstm += " order by madt.origid desc";

	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(10); newlb.setMold("paging");
	newlb.addEventListener("onSelect", auditclik);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid","datecreated","melref","parent_csgn","audituser","astatus","auditdate","fc6_grn","remarks" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

// Show 'em CSGN based on user location
void showCSGNlist(String ilocation)
{
	Object[] csgnhds =
	{
		new listboxHeaderWidthObj("CSGN",true,"80px"),
		new listboxHeaderWidthObj("BATCH",true,""),
	};
	Listbox newlb = lbhand.makeVWListbox_Width(melcsgn_holder, csgnhds, "melcsgn_lb", 3);

	sqlstm = "select origid,csgn from mel_csgn where rwlocation='" + ilocation + "' and mstatus='COMMIT';";
	rcs = sqlhand.gpSqlGetRows(sqlstm);
	if(rcs.size() == 0) return;
	newlb.setRows(10);

	ArrayList kabom = new ArrayList();
	String[] fl = { "origid","csgn" };
	for(d : rcs)
	{
		ngfun.popuListitems_Data(kabom,fl,d);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

ITEMS_OFFSET = 5;
Object[] adtitemshds =
{
	new listboxHeaderWidthObj("No.",true,"50px"),
	new listboxHeaderWidthObj("Asset tag",true,"100px"),
	new listboxHeaderWidthObj("Serial",true,"100px"),
	new listboxHeaderWidthObj("MEL item",true,"200px"),
	new listboxHeaderWidthObj("RW Stockname",true,"200px"),

	new listboxHeaderWidthObj("Grd",true,"50px"),
	new listboxHeaderWidthObj("Brand",true,"90px"),
	new listboxHeaderWidthObj("Type",true,"50px"),
	new listboxHeaderWidthObj("Model",true,"90px"),
	new listboxHeaderWidthObj("Proc / Monitor",true,"90px"),

	new listboxHeaderWidthObj("P.Speed / M.Size",true,""),
	new listboxHeaderWidthObj("M.Type",true,""),
	new listboxHeaderWidthObj("Color",true,""),
	new listboxHeaderWidthObj("Case",true,""),
	new listboxHeaderWidthObj("COA",true,""),
	new listboxHeaderWidthObj("COA2",true,""),
	new listboxHeaderWidthObj("RAM",true,""),
	new listboxHeaderWidthObj("HDD",true,""),
	new listboxHeaderWidthObj("CDROM1",true,""),
	new listboxHeaderWidthObj("Comment",true,""),
	new listboxHeaderWidthObj("Webcam",true,""),
	new listboxHeaderWidthObj("B.Tooth",true,"50px"),
	new listboxHeaderWidthObj("F.Print",true,"50px"),
	new listboxHeaderWidthObj("C.Reader",true,"50px"),

	new listboxHeaderWidthObj("Barcode",true,"40px"),
	new listboxHeaderWidthObj("Notes",true,""),
	new listboxHeaderWidthObj("Operability1",true,""),
	new listboxHeaderWidthObj("Operability2",true,""),
	new listboxHeaderWidthObj("Operability3",true,""),
	new listboxHeaderWidthObj("Operability4",true,""),
	new listboxHeaderWidthObj("Operability5",true,""),
	new listboxHeaderWidthObj("Appearance1",true,""),
	new listboxHeaderWidthObj("Appearance2",true,""),
	new listboxHeaderWidthObj("Appearance3",true,""),
	new listboxHeaderWidthObj("Appearance4",true,""),
	new listboxHeaderWidthObj("Appearance5",true,""),
	new listboxHeaderWidthObj("Completeness1",true,""),
	new listboxHeaderWidthObj("Completeness2",true,""),
	new listboxHeaderWidthObj("Completeness3",true,""),
	new listboxHeaderWidthObj("Completeness4",true,""),
	new listboxHeaderWidthObj("Completeness5",true,""),

	new listboxHeaderWidthObj("Grade",true,"50px"),
	new listboxHeaderWidthObj("Form factor",true,""),
	new listboxHeaderWidthObj("Case color",true,""),
	new listboxHeaderWidthObj("Laptop screen size",true,""),
	new listboxHeaderWidthObj("HDD size",true,""),
	new listboxHeaderWidthObj("RAM size",true,""),
	new listboxHeaderWidthObj("RAM sticks",true,""),
	new listboxHeaderWidthObj("DIMM slot",true,""),
	new listboxHeaderWidthObj("OS",true,""),
	new listboxHeaderWidthObj("Media drives",true,""),
	new listboxHeaderWidthObj("HDD wiped",true,""),
	new listboxHeaderWidthObj("HDD destroyed",true,""),
	new listboxHeaderWidthObj("HDD serial",true,""),
};

void show_CSGNAudit_itemcount(String icsgn)
{
	melcsgncounter_header.setValue("");
	if(icsgn.equals("")) return;
	sqlstm = "select count(origid) as csgnitemcount from mel_inventory where parent_id=" + icsgn + ";";
	r = sqlhand.gpSqlFirstRow(sqlstm);
	itnc = 0;
	if(r != null) itnc = r.get("csgnitemcount");

	lbc = audititems_lb.getItemCount();

	kts = "[ CSGN " + icsgn + " Qty = " + itnc.toString() + " :: Current MELADT Qty = " + lbc.toString() + " ]";
	melcsgncounter_header.setValue(kts);
}

// @params iatg: the asset-tag, icsgn: linking parent csgn id
void addAsset_ToMELADT(String iatg, String icsgn)
{
	if(icsgn.equals(""))
	{
		guihand.showMessageBox("ERR: please assign a CSGN to this audit-form");
		return;
	}
	Listbox newlb = null;
	if(adtitems_holder.getFellowIfAny("audititems_lb") == null)
	{
		newlb = lbhand.makeVWListbox_Width(adtitems_holder, adtitemshds, "audititems_lb", 20);
		newlb.setMultiple(true); newlb.setCheckmark(true);
	}
	else
	{
		newlb = adtitems_holder.getFellowIfAny("audititems_lb");
	}

	if(iatg.equals("")) return;

	if(lbhand.ExistInListbox(audititems_lb,iatg,0)) // check exist atg in LB
	{
		guihand.showMessageBox("ERR: Asset-tag already in the list..");
		return;
	}

	sqlstm = "select * from mel_inventory where rw_assettag='" + iatg + "' and parent_id=" + icsgn + " and audit_id is null;";
	r = sqlhand.gpSqlFirstRow(sqlstm); // get mel_inventory rec by iatg
	if(r == null)
	{
		guihand.showMessageBox("ERR: Cannot get record, either invalid asset-tag or wrong CSGN or already in a different audit-form..");
		return;	
	}

	ArrayList kabom = new ArrayList();
	kabom.add("999"); // Row count
	ngfun.popuListitems_Data(kabom,audititems_lb_fl,r);
	lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
	refresh_Items_rowcount();

	show_CSGNAudit_itemcount(icsgn);
}

// Call-back in itmdoubleclik to put selected rw-stockname and type to selected list-items
void sumbatStockName(String irwstockname, String itype)
{
	if(adtitems_holder.getFellowIfAny("audititems_lb") == null) return;
	if(audititems_lb.getSelectedCount() < 1) return;
	jk = audititems_lb.getSelectedItems().toArray();
	for(i=0; i<jk.length; i++)
	{
		lbhand.setListcellItemLabel(jk[i], 4, irwstockname); // refer to adtitemshds for item posisi
		lbhand.setListcellItemLabel(jk[i], 7, itype);
	}
}

// ijk: getselecteditems().toArray()
void removeSelectedAuditItems(Object ijk)
{
	atgs = "";
	for(i=0; i<ijk.length; i++)
	{
		atgs += "'" + lbhand.getListcellItemLabel(ijk[i],0) + "',";
		ijk[i].setParent(null);
	}
	// clear linking mel_inventory.audit_id
	try { atgs = atgs.substring(0,atgs.length()-1); } catch (Exception e) {}
	sqlstm = "update mel_inventory set audit_id=null where rw_assettag in (" + atgs + ");";
	sqlhand.gpSqlExecuter(sqlstm);
}
