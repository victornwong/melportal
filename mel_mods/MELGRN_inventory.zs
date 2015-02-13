import org.victor.*;
// MEL-GRN inventory management funcs - knockoff from goodsReceive_v2.zul(local GRN module)

// 07/01/2015: knockoff from goodsReceive_v2.zul(local GRN module)
// Inject stock items and qtys, only item with pre-def product-name will work
// use palletid 4=UNKNOWN (TODO chg to "WH PALLET" id for fc5012)
// IMPORTANT chg pallet-loca to AUDIT . GRN->AUDIT process, F30 palletid = 4, F12=4452
// RETURN: asset-tags in sql-ready string format
String updateInventory_GRNItems()
{
	AUDIT_PALLET_ID = "4"; // testing on F30 db
	try
	{
		log_assettags = "";
		//shpc = kiboo.replaceSingleQuotes( g_shipmentcode.getValue().trim() );
		shpc = "TEST MEL SHIPIN";
		tdate = calcFocusDate( kiboo.todayISODateTimeString() ).toString();
		sqlstm = "declare @maxid int; declare @maxseq int; declare @prodid varchar(200); declare @_masterid int; ";
		qty = "1";
		ret_assettags = "";

		ki = impsn_lb.getItems().toArray();
		for(i=0;i<ki.length;i++)
		{
			atg = lbhand.getListcellItemLabel(ki[i],PARSE_ASSETTAG_POS); // asset-tag
			snm = lbhand.getListcellItemLabel(ki[i],PARSE_SNUM_POS); // serial-no
			itm = lbhand.getListcellItemLabel(ki[i],PARSE_ITEMDESC_POS); // item-desc (must be def inside prod-name tbl mr008)
			//xcsgn = lbhand.getListcellItemLabel(ki[i],PARSE_CSGN_NO_POS); // csgn no.
			//xdr = lbhand.getListcellItemLabel(ki[i],PARSE_DATERECEIVED_POS); // date equip recv

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

		f30_gpSqlExecuter(sqlstm);
		//sqlhand.rws_gpSqlExecuter(sqlstm);
		//lgstr = "Update inventory : " + log_assettags;
		//add_RWAuditLog(JN_linkcode(),"", lgstr, useraccessobj.username);

		try { ret_assettags = ret_assettags.substring(0,ret_assettags.length()-1); } catch (Exception e) {}
		return ret_assettags;

	} catch (Exception e) {}
}

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

// FOCUS5010 table-refs
GRN_EXTRAHEADEROFF = "u002c";
GRN_EXTRAOFF = "u012c";
GRN_VOUCHERTYPE = "1281";

void inject_GRN_Headers(String[] hdv)
{
	kdate = calcFocusDate("2007-03-31");
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
	f30_gpSqlExecuter(sqlstm1);

	sqlstm2 = "select headerid,voucherno from header where login='" + lgn + "';"; // get inserted header.headerid
	r = f30_gpSqlFirstRow(sqlstm2);
	hdv[0] = r.get("headerid").toString();
	hdv[3] = r.get("voucherno");

	sqlstm3 = "update header set login='su' where headerid=" + hdv[0];
	f30_gpSqlExecuter(sqlstm3);

	// newshipmentcodeyh,grnremarksyh (for FOCUS5012 need these 2 extra-fields)
	// data.DO_EXTRAHEADEROFF - u002c.extraid
	sqlstm4 = "declare @maxid int; set @maxid = (select max(extraid)+1 from " + GRN_EXTRAHEADEROFF + "); " +
	"insert into " + GRN_EXTRAHEADEROFF + " (extraid, vendorrefyh, narrationyh, receipttypeyh, receivedbyyh, ponoyh, shipmentcodeyh, itemtypeyh) values " +
	"(@maxid, '', '', '', '', '" + lgn + "', '', '');";

	f30_gpSqlExecuter(sqlstm4);

	sqlstm5 = "select extraid from " + GRN_EXTRAHEADEROFF + " where ponoyh='" + lgn + "';";
	r = f30_gpSqlFirstRow(sqlstm5);
	hdv[1] = r.get("extraid").toString();

	sqlstm6 = "update " + GRN_EXTRAHEADEROFF + " set ponoyh='' where extraid=" + hdv[1]; // blank-it
	f30_gpSqlExecuter(sqlstm6);

	// data.GRN_EXTRAOFF = u012c.extraid
	sqlstm7 = "declare @maxid int; set @maxid = (select max(extraid)+1 from " + GRN_EXTRAOFF + ");" +
	"insert into " + GRN_EXTRAOFF + " (extraid,remarksyh) values (@maxid,'" + lgn + "');";

	f30_gpSqlExecuter(sqlstm7);

	sqlstm8 = "select extraid from " + GRN_EXTRAOFF + " where remarksyh='" + lgn + "';";
	r = f30_gpSqlFirstRow(sqlstm8);
	hdv[2] = r.get("extraid").toString();

	sqlstm9 = "update " + GRN_EXTRAOFF + " set remarksyh='' where extraid=" + hdv[2]; // blank-it
	f30_gpSqlExecuter(sqlstm9);
}

void inject_FC6GRN(String iasset_tags)
{
	// headvals[0] = headerid, headvals[1] = DO_EXTRAHEADEROFF, headvals[2] = DO_EXTRAOFF, headvals[3] = voucherno
	String[] headvals = new String[4];
	linecount = 0;
	kdate = calcFocusDate("2007-03-31");

	//atgs = "'91003526','91003528','91003529','91003531','91003532','91003534','91003535'";
	sqlstm1 = "select m.masterid as pcode, p.masterid as tags6v from mr001 AS m left join " +
	"dbo.u0001 AS u ON m.Eoff = u.ExtraId left join dbo.mr008 AS p ON u.ProductNameYH = p.MasterId " +
	"where m.code2 in (" + iasset_tags + ");";

	rx = f30_gpSqlGetRows(sqlstm1);
	// TODO have to check how recs found based on asset-tags, if not equal, error-return
	
	inject_GRN_Headers(headvals);
	//kk = "headerid=" + headvals[0] + "\nu002c.extraid=" + headvals[1] + "\nu012c.extraid=" + headvals[2] + "\nvoucherno=" + headvals[3];
	//debuglabel.setValue(kk);

	mainsqlstm = "declare @dmaxid int; declare @imaxid int; ";

	for(d : rx)
	{
		prodcode = (d.get("pcode") == null) ? "0" : d.get("pcode").toString();
		tags6 = (d.get("tags6v") == null) ? "0" : d.get("tags6v").toString();

		// data.salesoff = indta.salesid (just assume qty=1 for MEL grn)
		mainsqlstm += "set @imaxid = (select max(salesid)+1 from indta); " +
		"insert into indta (salesid,quantity,stockvalue,rate,gross,qty2,subprocess,unit," +
		"input0,output0,input1,output1,input2,output2,input3,output3," +
		"input4,output4,input5,output5,input6,output6,input7,output7," +
		"input8,output8,input9,output9) values ( @imaxid,1,0,0,0,1,0,0x00, " +
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
		"@dmaxid, " + kdate + "," + GRN_VOUCHERTYPE + ", '" + headvals[3] +"', 1251, " + prodcode + "," +
		"3, 3, 0, 9, 0, 0, 0, 2622464, 0, 0, " + tags6 + ", " +
		headvals[0] + "," + headvals[2] + "," + headvals[1] + ",@imaxid," +
		"1078," + kdate + ",80, 0, 0, 0, 0, 1, 0, 0, 0," +
		"0, 0, 0);";

		linecount++;
	}

	mainsqlstm += "update header set noentries=" + linecount.toString() + ", tnoentries=" + linecount.toString() +
	" where headerid=" + headvals[0] + ";"; // update no. lines in header

	f30_gpSqlExecuter(mainsqlstm);
	alert("boom t.grn..");
}
