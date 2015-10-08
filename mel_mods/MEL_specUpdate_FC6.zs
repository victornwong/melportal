import org.victor.*;
// MEL-GRN inventory management funcs - knockoff from goodsReceive_v2.zul(local GRN module)
// knockoff from MELGRN_inventory.zs

// FOCUS5010 table-refs
// GRN_ACCOUNT_NO = "1251"; testing account
GRN_ACCOUNT_NO = "2509"; // 0J0.mr000 MACQUARIE EQUIPMENT LEASING - AP
GRN_EXTRAHEADEROFF = "u002c";
GRN_EXTRAOFF = "u012c";
GRN_VOUCHERTYPE = "1281";

// 07/01/2015: knockoff from goodsReceive_v2.zul(local GRN module)
// used by admin for now .. later put into another module to FAST add/minus stock
// itype: 1=minus stock, 2=add stock
void minusAddFocus_Stock(int itype, int qty)
{
	try
	{
		if(itype == 1) qty *= -1;
		tdate = calcFocusDate( kiboo.todayISODateTimeString() ).toString();
		sqlstm = "declare @_masterid int; ";

		ki = impsn_lb.getItems().toArray();
		for(i=0;i<ki.length;i++)
		{
			//ki = jk[i].getChildren().toArray();
			//atg = kiboo.replaceSingleQuotes( ki[2].getValue().trim() );
			atg = lbhand.getListcellItemLabel(ki[i],PARSE_ASSETTAG_POS); // asset-tag

			if(!atg.equals(""))
			{
				sqlstm += "if exists(select 1 from mr001 where code2='" + atg + "')" +
				"begin " +
				"set @_masterid = (select masterid from mr001 where code2='" + atg + "'); " +
				"insert into ibals (code,date_,dep,qiss,qrec,val,qty2) ";

				switch(itype)
				{
					case 1: // do QISS
						sqlstm +=
						"values (@_masterid," + tdate + ",0," + qty.toString() + ",0,0,0); " +
						"end; ";
						break;

					case 2: // do QREC
					sqlstm +=
						"values (@_masterid," + tdate + ",0,0," + qty.toString() + ",0,0); " +
						"end; ";
						break;
				}
			}
		}
		//sqlhand.rws_gpSqlExecuter(sqlstm);
		f30_gpSqlExecuter(sqlstm);
	} catch (Exception e) {}	
}

// 11/03/2015: Same as updateInventory_GRNItems() but refer to listbox of audit-items instead of melgrn items
// Inject stock items and qtys, only item with pre-def product-name will work
// use palletid 4=UNKNOWN (TODO chg to "WH PALLET" id for fc5012)
// IMPORTANT chg pallet-loca to AUDIT . GRN->AUDIT process, F10 palletid = 4, F12=4452
// RETURN: asset-tags in sql-ready string format
String updateInventory_AuditItems()
{
	if(adtitems_holder.getFellowIfAny("audititems_lb") == null) return "";
	if(audititems_lb.getItemCount() == 0) return "";

	//AUDIT_PALLET_ID = "4"; // testing on F10 db
	//AUDIT_PALLET_ID = "4452"; // F12 db, "AUDIT" pallet
	AUDIT_PALLET_ID = (TESTING_MODE) ? "4452" : "4497"; // 0J0=4452, 0J1=4497 for "AUDIT" pallet in mr003
	shpc = "MEL SHIPMENT";
	tdate = calcFocusDate( kiboo.todayISODateTimeString() ).toString();
	sqlstm = log_assettags = ret_assettags = "";
	qty = "1";
	//shpc = kiboo.replaceSingleQuotes( g_shipmentcode.getValue().trim() );
	try
	{
		sqlstm = "declare @maxid int; declare @maxseq int; declare @prodid varchar(200); declare @_masterid int; ";

		jk = audititems_lb.getItems().toArray();

		for(i=0;i<jk.length;i++)
		{
			itm = lbhand.getListcellItemLabel(jk[i],4);
			atg = lbhand.getListcellItemLabel(jk[i],1);
			snm = lbhand.getListcellItemLabel(jk[i],2);

			if(!itm.equals("")) // only entry with item-name
			{
				log_assettags += atg + "(" + snm + " / " + qty + "), ";

				sqlstm += "if not exists(select 1 from mr001 where code2='" + atg + "')" +
				"begin " +
				"set @maxid = (select max(masterid)+1 from mr001);" +
				"set @maxseq = (select max(sequence)+1 from mr001);" +
				"set @prodid = (select top 1 masterid from mr008 where name='" + itm + "'); " +

				"insert into mr001 (masterid,sequence,name,code,code2,limit,l2,type,attribute,eoff,doff,creditdays,date_,time_,limit2) " +
				"values (@maxid,@maxseq, " +
				"'" + atg + "','" + snm + "','" + atg + "', " +
				"0,-1,131,0,@maxid,0,0," + tdate + ",0xe332e,0); " +

				"insert into u0001 (extraid,productnameyh,palletnoyh,shipmentcodeyh) values (@maxid,@prodid," + AUDIT_PALLET_ID + ",'" + shpc + "'); " +

				//"insert into ibals (code,date_,dep,qiss,qrec,val,qty2) " +
				//"values (@maxid," + tdate + ",0,-1,1,1,1); " +

				//"insert into ibals (code,date_,dep,qiss,qrec,val,qty2) " +
				//"values (@maxid," + tdate + ",0,0,0,0," + qty + "); " +

				"insert into ibals (code,date_,dep,qiss,qrec,val,qty2) " +
				"values (@maxid," + tdate + ",0,0,0,0,0); " +

				"end else begin " +
				"set @_masterid = (select masterid from mr001 where code2='" + atg + "'); " +

				// for RWMS, need this for EOL equips
				"insert into ibals (code,date_,dep,qiss,qrec,val,qty2) " +
				"values (@_masterid," + tdate + ",0,0,0,0,0); " +
				"update mr001 set name='" + itm + "',code='" + snm + "' where code2='" + atg + "';" +
				"end;";

				ret_assettags += "'" + atg + "',";
			}
		}
		if(TESTING_MODE) f30_gpSqlExecuter(sqlstm);
		else fJ1_gpSqlExecuter(sqlstm);
		//sqlhand.rws_gpSqlExecuter(sqlstm);
		//lgstr = "Update inventory : " + log_assettags;
		//add_RWAuditLog(JN_linkcode(),"", lgstr, useraccessobj.username);

		try { ret_assettags = ret_assettags.substring(0,ret_assettags.length()-1); } catch (Exception e) {}
		return ret_assettags;

	} catch (Exception e) {}
}

// 11/03/2015: same as postSpecs() but modif to get things from listbox
// uses mel_specupdate_v2.specs_sql_fields for table field-names
boolean postSpecs_LB()
{
	if(adtitems_holder.getFellowIfAny("audititems_lb") == null) return false;
	if(audititems_lb.getItemCount() == 0) return false;

	jk = audititems_lb.getItems().toArray();
	sqlstm = "";
	for(i=0;i<jk.length;i++)
	{
		itmn = lbhand.getListcellItemLabel(jk[i],4);
		atg = lbhand.getListcellItemLabel(jk[i],1);

		if(!atg.equals("NOTAG") && !atg.equals("")) // ignore NOTAG or blank asset-tags -- inserted by RWMS
		{
			fql = "";
			sqlstm += "update u0001 set ";
			for(k=0; k<specs_sql_fields.length; k++)
			{
				cix = k + ITEMS_OFFSET;
				ct = lbhand.getListcellItemLabel(jk[i],cix);
				fql += specs_sql_fields[k] + "='" + ct + "',";
			}
			try { fql = fql.substring(0,fql.length()-1); } catch (Exception e) {}

			sqlstm += fql +
			", productnameyh=(select cast(masterid as varchar) from mr008 where name='" + itmn + "') " +
			"where extraid=(select eoff from mr001 where code2='" + atg + "');";
		}
	}
	if(TESTING_MODE) f30_gpSqlExecuter(sqlstm);
	else fJ1_gpSqlExecuter(sqlstm);

	return true;
}

void inject_GRN_Headers(String[] hdv)
{
	//kdate = calcFocusDate("2007-03-31"); for F10 testing db
	kdate = calcFocusDate( kiboo.todayISODateString() ).toString();
	lgn = "upload" + Math.round(Math.random() * 100).toString();

	// data.headeroff = header.headerid
	sqlstm1 = "declare @domaxid int;" +
	"set @domaxid = (select max(cast(voucherno as int))+1 from header where vouchertype=" + GRN_VOUCHERTYPE + ");" +
	"insert into header (" +
	"id, version, noentries, tnoentries, login, date_, time_," +
	"flags, flags2, defcurrency," +
	"vouchertype, voucherno, approvedby0, approvedby1, approvedby2) values (" +
	"0x0001, 0x5b, 0, 0, '" + lgn + "', " + kdate + ", 0x0a3b00," +
	"0x0024, 4549, 0x00," +
	GRN_VOUCHERTYPE + ", @domaxid, 3, 0, 0 );";

	if(TESTING_MODE) f30_gpSqlExecuter(sqlstm1);
	else fJ1_gpSqlExecuter(sqlstm1);

	sqlstm2 = "select headerid,voucherno from header where login='" + lgn + "';"; // get inserted header.headerid
	r = (TESTING_MODE) ? f30_gpSqlFirstRow(sqlstm2) : fJ1_gpSqlFirstRow(sqlstm2);
	hdv[0] = r.get("headerid").toString();
	hdv[3] = r.get("voucherno");

	sqlstm3 = "update header set login='su' where headerid=" + hdv[0];
	if(TESTING_MODE) f30_gpSqlExecuter(sqlstm3);
	else fJ1_gpSqlExecuter(sqlstm3);

	// newshipmentcodeyh,grnremarksyh (for FOCUS5012 need these 2 extra-fields)
	// data.DO_EXTRAHEADEROFF - u002c.extraid
	/*
	sqlstm4 = "declare @maxid int; set @maxid = (select max(extraid)+1 from " + GRN_EXTRAHEADEROFF + "); " +
	"insert into " + GRN_EXTRAHEADEROFF + " (extraid, vendorrefyh, narrationyh, receipttypeyh, receivedbyyh, ponoyh, shipmentcodeyh, itemtypeyh) values " +
	"(@maxid, '', '', '', '', '" + lgn + "', '', '');";
	*/

	sqlstm4 = "declare @maxid int; set @maxid = (select max(extraid)+1 from " + GRN_EXTRAHEADEROFF + "); " +
	"insert into " + GRN_EXTRAHEADEROFF + " (extraid, vendorrefyh, narrationyh, receipttypeyh, receivedbyyh, ponoyh, shipmentcodeyh, itemtypeyh, newshipmentcodeyh, grnremarksyh) values " +
	"(@maxid, '', '', '', '', '" + lgn + "', '', '', '', '');";

	if(TESTING_MODE) f30_gpSqlExecuter(sqlstm4);
	else fJ1_gpSqlExecuter(sqlstm4);

	sqlstm5 = "select extraid from " + GRN_EXTRAHEADEROFF + " where ponoyh='" + lgn + "';";
	r = (TESTING_MODE) ? f30_gpSqlFirstRow(sqlstm5) : fJ1_gpSqlFirstRow(sqlstm5);
	hdv[1] = r.get("extraid").toString();

	sqlstm6 = "update " + GRN_EXTRAHEADEROFF + " set ponoyh='' where extraid=" + hdv[1]; // blank-it

	if(TESTING_MODE) f30_gpSqlExecuter(sqlstm6);
	else fJ1_gpSqlExecuter(sqlstm6);

	// data.GRN_EXTRAOFF = u012c.extraid
	sqlstm7 = "declare @maxid int; set @maxid = (select max(extraid)+1 from " + GRN_EXTRAOFF + ");" +
	"insert into " + GRN_EXTRAOFF + " (extraid,remarksyh) values (@maxid,'" + lgn + "');";

	if(TESTING_MODE) f30_gpSqlExecuter(sqlstm7);
	else fJ1_gpSqlExecuter(sqlstm7);

	sqlstm8 = "select extraid from " + GRN_EXTRAOFF + " where remarksyh='" + lgn + "';";
	r = (TESTING_MODE) ? f30_gpSqlFirstRow(sqlstm8) : fJ1_gpSqlFirstRow(sqlstm8);
	hdv[2] = r.get("extraid").toString();

	sqlstm9 = "update " + GRN_EXTRAOFF + " set remarksyh='' where extraid=" + hdv[2]; // blank-it

	if(TESTING_MODE) f30_gpSqlExecuter(sqlstm9);
	else fJ1_gpSqlExecuter(sqlstm9);
}

String inject_FC6GRN(String iasset_tags)
{
	// headvals[0] = headerid, headvals[1] = DO_EXTRAHEADEROFF, headvals[2] = DO_EXTRAOFF, headvals[3] = voucherno
	String[] headvals = new String[4];
	linecount = 0;
	kdate = calcFocusDate( kiboo.todayISODateString() ).toString();

	sqlstm1 = "select m.masterid as pcode, p.masterid as tags6v from mr001 AS m left join " +
	"dbo.u0001 AS u ON m.Eoff = u.ExtraId left join dbo.mr008 AS p ON u.ProductNameYH = p.MasterId " +
	"where m.code2 in (" + iasset_tags + ");";

	rx = (TESTING_MODE) ? f30_gpSqlGetRows(sqlstm1) : fJ1_gpSqlGetRows(sqlstm1);
	inject_GRN_Headers(headvals);
	
	//kk = "headerid=" + headvals[0] + "\nu002c.extraid=" + headvals[1] + "\nu012c.extraid=" + headvals[2] + "\nvoucherno=" + headvals[3];
	//debuglabel.setValue(kk);

	mainsqlstm = "declare @dmaxid int; declare @imaxid int; ";

	grn_account_inject = (TESTING_MODE) ? GRN_ACCOUNT_NO : "3647"; // 0J0=2509, 0J1=3647 for "MACQUARIE EQUIPMENT LEASING - AP"

	for(d : rx)
	{
		prodcode = (d.get("pcode") == null) ? "0" : d.get("pcode").toString();
		tags6 = (d.get("tags6v") == null) ? "0" : d.get("tags6v").toString();

		// data.salesoff = indta.salesid (just assume qty=1 for MEL grn)
		mainsqlstm += "set @imaxid = (select max(salesid)+1 from indta); " +
		"insert into indta (salesid,quantity,stockvalue,rate,gross,qty2,subprocess,unit," +
		"input0,output0,input1,output1,input2,output2,input3,output3," +
		"input4,output4,input5,output5,input6,output6,input7,output7," +
		"input8,output8,input9,output9) values ( @imaxid,0,0,0,0,0,0,0x00, " +
		"0,0,0,0,0,0,0,0," +
		"0,0,0,0,0,0,0,0," +
		"0,0,0,0);";

		mainsqlstm += "set @dmaxid = (select max(bodyid)+1 from data); " +
		"insert into data (" +
		"bodyid, date_, vouchertype, voucherno, bookno, productcode," +
		"tags0, tags1, tags2, tags3, amount1, amount2, originalamount, flags, billwiseoff, links0, tags6," +
		"headeroff, extraoff, extraheaderoff, salesoff," +
		"code, duedate, sizeofrec, links1, links2, links3, linktoprbatch, exchgrate, tags4, tags5, tags7, " +
		"binnoentries, reserveno, reservetype) values (" +
		"@dmaxid, " + kdate + "," + GRN_VOUCHERTYPE + ", '" + headvals[3] +"'," + grn_account_inject + ", " + prodcode + "," +
		"3, 3, 0, 9, 0, 0, 0, 2622464, 0, 0, " + tags6 + ", " +
		headvals[0] + "," + headvals[2] + "," + headvals[1] + ",@imaxid," +
		"1078," + kdate + ",80, 0, 0, 0, 0, 1, 0, 0, 0," +
		"0, 0, 0);";

		linecount++;
	}

	mainsqlstm += "update header set noentries=" + linecount.toString() + ", tnoentries=" + linecount.toString() +
	" where headerid=" + headvals[0] + ";"; // update no. lines in header

	if(TESTING_MODE) f30_gpSqlExecuter(mainsqlstm);
	else fJ1_gpSqlExecuter(mainsqlstm);

	return headvals[3]; // return voucher-no
}

/* unused codes - pending requirements

	boolean postSpecs()
	{
		try
		{
			jk = grn_rows.getChildren().toArray();
			sqlstm = "";
			for(i=0;i<jk.length;i++)
			{
				ki = jk[i].getChildren().toArray();
				itmn = ki[2].getValue().trim();
				atg = ki[3].getValue();

				if(!atg.equals("NOTAG") && !atg.equals("")) // ignore NOTAG or blank asset-tags -- inserted by RWMS
				{
					sqlstm += "update u0001 set ";
					fql = "";
					for(k=0; k<specs_fields.length;k++)
					{
						cix = k + 5;

						if(ki[cix] instanceof Listbox)
							ct = ki[cix].getSelectedItem().getLabel();
						else
							ct = kiboo.replaceSingleQuotes( ki[cix].getValue().trim() );

						fql += specs_sql_fields[k] + "='" + ct + "',";
					}
					try { fql = fql.substring(0,fql.length()-1); } catch (Exception e) {}
					sqlstm += fql +
					", productnameyh=(select cast(masterid as varchar) from mr008 where name='" + itmn + "') " +
					"where extraid=(select eoff from mr001 where code2='" + atg + "');";
				}
			}
			//alert(sqlstm);
			//sqlhand.rws_gpSqlExecuter(sqlstm);
			f30_gpSqlExecuter(sqlstm);
			return true;
		} catch (Exception e) { return false; }
	}

	// 07/01/2015: knockoff from goodsReceive_v2.zul(local GRN module)
	// Inject stock items and qtys, only item with pre-def product-name will work
	// use palletid 4=UNKNOWN (TODO chg to "WH PALLET" id for fc5012)
	// IMPORTANT chg pallet-loca to AUDIT . GRN->AUDIT process, F10 palletid = 4, F12=4452
	// RETURN: asset-tags in sql-ready string format
	String updateInventory_GRNItems()
	{
		AUDIT_PALLET_ID = "4"; // testing on F10 db
		shpc = "MEL SHIPMENT";
		tdate = calcFocusDate( kiboo.todayISODateTimeString() ).toString();
		sqlstm = log_assettags = ret_assettags = "";
		qty = "1";
		//shpc = kiboo.replaceSingleQuotes( g_shipmentcode.getValue().trim() );
		try
		{
			sqlstm = "declare @maxid int; declare @maxseq int; declare @prodid varchar(200); declare @_masterid int; ";

			jk = grn_rows.getChildren().toArray();

			for(i=0;i<jk.length;i++)
			{
				ki = jk[i].getChildren().toArray();
				itm = ki[2].getValue().trim();
				atg = ki[3].getValue();
				snm = ki[4].getValue();

				if(!itm.equals("")) // only entry with item-name
				{
					log_assettags += atg + "(" + snm + " / " + qty + "), ";

					sqlstm += "if not exists(select 1 from mr001 where code2='" + atg + "')" +
					"begin " +
					"set @maxid = (select max(masterid)+1 from mr001);" +
					"set @maxseq = (select max(sequence)+1 from mr001);" +
					"set @prodid = (select top 1 masterid from mr008 where name='" + itm + "'); " +

					"insert into mr001 (masterid,sequence,name,code,code2,limit,l2,type,attribute,eoff,doff,creditdays,date_,time_,limit2) " +
					"values (@maxid,@maxseq, " +
					"'" + atg + "','" + snm + "','" + atg + "', " +
					"0,-1,131,0,@maxid,0,0," + tdate + ",0xe332e,0); " +

					"insert into u0001 (extraid,productnameyh,palletnoyh,shipmentcodeyh) values (@maxid,@prodid," + AUDIT_PALLET_ID + ",'" + shpc + "'); " +

					"insert into ibals (code,date_,dep,qiss,qrec,val,qty2) " +
					"values (@maxid," + tdate + ",0,0," + qty + ",0,0); " +

					"end else begin " +
					"set @_masterid = (select masterid from mr001 where code2='" + atg + "'); " +

					// for RWMS, need this for EOL equips
					//"insert into ibals (code,date_,dep,qiss,qrec,val,qty2) " +
					//"values (@_masterid," + tdate + ",0,0," + qty + ",0,0); " +
					
					//"update mr001 set name='" + itm + "',code='" + snm + "' where code2='" + atg + "';" +
					"end;";

					ret_assettags += "'" + atg + "',";
				}
			}

			//alert(sqlstm);
			f30_gpSqlExecuter(sqlstm);
			//sqlhand.rws_gpSqlExecuter(sqlstm);
			//lgstr = "Update inventory : " + log_assettags;
			//add_RWAuditLog(JN_linkcode(),"", lgstr, useraccessobj.username);

			try { ret_assettags = ret_assettags.substring(0,ret_assettags.length()-1); } catch (Exception e) {}
			return ret_assettags;

		} catch (Exception e) {}
	}
*/
