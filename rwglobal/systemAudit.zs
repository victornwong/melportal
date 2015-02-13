import java.util.*;
import java.text.*;

// Funcs to process rw_systemaudit
// Written by Victor Wong (01/08/2013)
// void add_RWAuditLog(String ilinkc, String isubc, String iwhat, String iuser) -- rwsqlfuncs.zs

// Can be used in other mods to show system-audit logs
void showSystemAudit(Div ihold, String ilinkc, String isubc)
{
Object[] sysloglb_hds =
{
	new listboxHeaderWidthObj("Dated",true,"100px"),
	new listboxHeaderWidthObj("User",true,"65px"),
	new listboxHeaderWidthObj("Logs",true,""),
};
	Listbox newlb = lbhand.makeVWListbox_Width(ihold, sysloglb_hds, "syslogs_lb", 5);
	SimpleDateFormat ldtf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

	// check req to filter by linking_sub
	chksub = " and linking_sub='" + isubc + "' ";
	if(isubc.equals("")) chksub = "";

	sqlstm = "select datecreated,username,audit_notes from rw_systemaudit where " +
	"linking_code='" + ilinkc + "'" + chksub + "order by datecreated desc";

	sylog = sqlhand.gpSqlGetRows(sqlstm);
	if(sylog.size() == 0) return;
	newlb.setRows(10);
	newlb.setMold("paging");
	//newlb.addEventListener("onSelect", new tkslbClick());
	ArrayList kabom = new ArrayList();
	for(dpi : sylog)
	{
		kabom.add( ldtf.format(dpi.get("datecreated")) );
		kabom.add(kiboo.checkNullString(dpi.get("username")));
		kn = (dpi.get("audit_notes") == null) ? "" : sqlhand.clobToString(dpi.get("audit_notes"));
		kabom.add(kn);
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}


