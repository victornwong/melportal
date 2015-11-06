import org.victor.*;
// MPF functions for MEL spec-update module

String[] mlbl = {
"Grd", "Brand", "Type", "Model", "Processor / Monitor", "P.Speed / M.Size", "M.Type", "Color",
"Case", "COA", "COA2", "RAM", "HDD", "CDROM1", "Comment", "Webcam",
"B.Tooth", "F.Print", "C.Reader",
};

String[] mcid = {
"m_grd", "m_brand", "m_type", "m_model", "m_processor", "m_msize", "m_mtype", "m_color",
"m_case", "m_coa", "m_coa2", "m_ram", "m_hdd", "m_cdrom1", "m_comment", "m_webcam",
"m_btooth", "m_fprint", "m_creader"
};

String[] mbtn = {
"bm_grd", "bm_brand", "bm_type", "bm_model", "bm_processor", "bm_msize", "bm_mtype", "bm_color",
"bm_case", "bm_coa", "bm_coa2", "bm_ram", "bm_hdd", "bm_cdrom1", "bm_comment", "bm_webcam",
"bm_btooth", "bm_fprint", "bm_creader"
};

String[] mctype = {
"lb", "tb", "lb", "tb", "lb", "lb", "tb", "lb",
"lb", "lb", "tb", "tb", "tb", "lb", "tb", "lb",
"lb", "lb", "lb",
};

String[] mclookup = {
"", "", "MEL_ITEM_TYPE", "", "MEL_PROCESSOR", "MEL_PROCESSOR_SPEED", "", "MEL_ADT_CASECOLOR",
"MEL_ADT_FORMFACTOR", "MEL_COA_NAMES", "", "", "", "MEL_ADT_MEDIADRIVES", "", "YESNO_DEF",
"YESNO_DEF","YESNO_DEF","YESNO_DEF",
};

String[] mel_lbl = {
"Barcode", "Notes", "Operability1",
"Operability2", "Operability3", "Operability4", "Operability5",
"Appearance1", "Appearance2", "Appearance3", "Appearance4", "Appearance5", 
"Completeness1", "Completeness2", "Completeness3", "Completeness4", "Completeness5",
"Grade", "Form factor", "Case color",
"Laptop screen size", "HDD size", "RAM size", "RAM sticks", "DIMM slot",
"OS", "Media drives", "HDD wiped", "HDD destroyed", "HDD serial",
};

String[] melcid = {
"ml_barcode", "ml_notes", "ml_operability",
"ml_operability2", "ml_operability3", "ml_operability4", "ml_operability5",
"ml_appearance", "ml_appearance2", "ml_appearance3", "ml_appearance4", "ml_appearance5",
"ml_completeness", "ml_completeness2", "ml_completeness3", "ml_completeness4", "ml_completeness5",
"ml_grade", "ml_formfactor", "ml_casecolor",
"ml_laptopscreensize", "ml_hddsize", "ml_ramsize", "ml_ramsticks", "ml_dimmslot",
"ml_os", "ml_mediadrives", "ml_hddwiped", "ml_hdddestroyed", "ml_hdddestsnum",
};

String[] melctype = {
"tb","tb","lb",
"lb","lb","lb","lb",
"lb","lb","lb","lb","lb", 
"lb","lb","lb","lb","lb",
"lb","lb","lb",
"lb","lb","lb","lb","lb",
"lb","lb","lb","lb","tb",
};

String[] melclookup = {
"","","MEL_ADT_OPERABILITY",
"MEL_ADT_OPERABILITY","MEL_ADT_OPERABILITY","MEL_ADT_OPERABILITY","MEL_ADT_OPERABILITY",
"MEL_ADT_APPEARANCE","MEL_ADT_APPEARANCE","MEL_ADT_APPEARANCE","MEL_ADT_APPEARANCE","MEL_ADT_APPEARANCE",
"MEL_ADT_COMPLETENESS","MEL_ADT_COMPLETENESS","MEL_ADT_COMPLETENESS","MEL_ADT_COMPLETENESS","MEL_ADT_COMPLETENESS",
"MEL_ADT_GRADE","MEL_ADT_FORMFACTOR","MEL_ADT_CASECOLOR",
"MEL_ADT_LAPTOPSCREEN","MEL_ADT_HDDSIZE","MEL_ADT_RAMSIZE","MEL_ADT_RAMSTICKS","MEL_ADT_DIMMSLOT",
"MEL_ADT_OS","MEL_ADT_MEDIADRIVES","YESNO_DEF","YESNO_DEF","",
};

String[] melbtn = {
"bml_barcode", "bml_notes", "bml_operability",
"bml_operability2", "bml_operability3", "bml_operability4", "bml_operability5",

"bml_appearance", "bml_appearance2", "bml_appearance3", "bml_appearance4", "bml_appearance5",
"bml_completeness", "bml_completeness2", "bml_completeness3", "bml_completeness4", "bml_completeness5",

"bml_grade", "bml_formfactor", "bml_casecolor",
"bml_laptopscreensize", "bml_hddsize", "bml_ramsize", "bml_ramsticks", "bml_dimmslot",
"bml_os", "bml_mediadrives", "bml_hddwiped", "bml_hdddestroyed", "bml_hdddestsnum",
};

void removeAuditItem()
{
	try
	{
		jk = grn_rows.getChildren().toArray();
		for(i=0;i<jk.length;i++)
		{
			ki = jk[i].getChildren().toArray();
			if(ki[0].isChecked()) jk[i].setParent(null);
		}
	} catch (Exception e) {}
}

void mpfToggCheckbox() // toggle checkboxes for 'em items
{
	try
	{
		jk = grn_rows.getChildren().toArray();
		for(i=0;i<jk.length;i++)
		{
			ki = jk[i].getChildren().toArray();
			ki[0].setChecked( (ki[0].isChecked()) ? false : true ); // assume 1st item is checkbox!!
		}
	} catch (Exception e) {}
}

void mpf_clearBoxes() // just clear 'em MPF mass-update specs boxes
{
	Object[] jkl = {
	m_grd, m_brand, m_type, m_model, m_processor, m_msize, m_mtype,
	m_color, m_case, m_coa, m_coa2, m_ram, m_hdd, m_cdrom1, m_comment,
	m_webcam, m_btooth, m_fprint, m_creader,
	ml_barcode, ml_notes, ml_operability,
	ml_operability2, ml_operability3, ml_operability4, ml_operability5,
	ml_appearance, ml_completeness, ml_grade, ml_formfactor, ml_casecolor,
	ml_laptopscreensize, ml_hddsize, ml_ramsize, ml_ramsticks, ml_dimmslot,
	ml_os, ml_mediadrives, ml_hddwiped, ml_hdddestroyed, ml_hdddestsnum,
	};
	for(i=0;i<jkl.length;i++)
	{
		if(jkl[i] instanceof org.zkoss.zul.Listbox)
		{
			jkl[i].setSelectedIndex(0);
		}
		else
		if(jkl[i] instanceof org.zkoss.zul.Textbox)
		{
			jkl[i].setValue("");
		}
	}
}

void mpf_UpdateAll()
{
}

void mpf_UpdateAll_listbox()
{
	mpf_pop.close();
	if(adtitems_holder.getFellowIfAny("audititems_lb") == null) return;
	if(audititems_lb.getSelectedCount() < 1) return;

	Object[] mpfdx = // this one must map against mel_specupdate_lb.adtitemshds
	{
		m_grd, m_brand, m_type, m_model, m_processor, m_msize, m_mtype, m_color,
		m_case, m_coa, m_coa2, m_ram, m_hdd, m_cdrom1, m_comment, m_webcam,
		m_btooth, m_fprint, m_creader,
		ml_barcode, ml_notes, ml_operability,
		ml_operability2, ml_operability3, ml_operability4, ml_operability5,
		ml_appearance, ml_appearance2, ml_appearance3, ml_appearance4, ml_appearance5,
		ml_completeness, ml_completeness2, ml_completeness3, ml_completeness4, ml_completeness5,
		ml_grade, ml_formfactor, ml_casecolor,
		ml_laptopscreensize, ml_hddsize, ml_ramsize, ml_ramsticks, ml_dimmslot,
		ml_os, ml_mediadrives, ml_hddwiped, ml_hdddestroyed, ml_hdddestsnum
	};

	jk = audititems_lb.getSelectedItems().toArray();
	for(i=0; i<jk.length; i++)
	{
		for(k=0; k<mpfdx.length; k++)
		{
			bva = "";
			if(mpfdx[k] instanceof org.zkoss.zul.Textbox) bva = kiboo.replaceSingleQuotes( mpfdx[k].getValue().trim() );
			if(mpfdx[k] instanceof org.zkoss.zul.Listbox) bva = mpfdx[k].getSelectedItem().getLabel();
			lbhand.setListcellItemLabel(jk[i],k+ITEMS_OFFSET,bva); // refer to mel_specupdate_lb.adtitemshds for posisi
		}
	}
	audititems_lb.invalidate();
}

void mpf_UpdateSingular_listbox(Component iob)
{
	mpf_pop.close();
	kk = iob.getId(); kk = kk.substring(1,kk.length());
	tobj = mpf_pop.getFellowIfAny(kk);
	if(tobj == null) return;
	spt = "";
	if(tobj instanceof org.zkoss.zul.Textbox)
	{
		spt = kiboo.replaceSingleQuotes( tobj.getValue().trim() );
		if(spt.equals("")) return;
	}
	else
	if(tobj instanceof org.zkoss.zul.Listbox)
		spt = tobj.getSelectedItem().getLabel();

	mut = -1;
	for(k=0; k<specs_mpf_names.length;k++) // scan through field-names to get index
	{
		if( specs_mpf_names[k].equals(kk) )
		{
			mut = k;
			break;
		}
	}
	if(mut != -1)
	{
		cix = 5 + mut;
		jk = audititems_lb.getSelectedItems().toArray();
		for(i=0;i<jk.length;i++)
		{
			lbhand.setListcellItemLabel(jk[i],cix,spt); // refer to mel_specupdate_lb.adtitemshds for posisi
		}
		mpf_lastupdate_blink.setValue("(" + kk + " updated..)");
	}
}

void mpfUpdate_specs2(Component iob)
{
	//mpf_pop.close();
	kk = iob.getId(); kk = kk.substring(1,kk.length());
	tobj = mpf_pop.getFellowIfAny(kk);
	if(tobj == null) return;
	spt = "";

	if(tobj instanceof org.zkoss.zul.Textbox)
	{
		spt = kiboo.replaceSingleQuotes( tobj.getValue().trim() );
		if(spt.equals("")) return;
	}
	else
	if(tobj instanceof org.zkoss.zul.Listbox)
		spt = tobj.getSelectedItem().getLabel();

	mut = -1;
	for(k=0; k<specs_mpf_names.length;k++) // scan through field-names to get index
	{
		if( specs_mpf_names[k].equals(kk) )
		{
			mut = k;
			break;
		}
	}
	//alert(mut + " :: " + (mut+5) + " :: " + spt + " :: " + tobj);
	if(mut != -1)
	{
		jk = grn_rows.getChildren().toArray();
		for(i=0;i<jk.length;i++)
		{
			ki = jk[i].getChildren().toArray();
			cix = 5 + mut;
			if(ki[0].isChecked())
			{
				if(ki[cix] instanceof org.zkoss.zul.Textbox)
				{
					ki[cix].setValue(spt);
				}
				else
				if(ki[cix] instanceof org.zkoss.zul.Listbox)
				{
					lbhand.matchListboxItems(ki[cix], spt);
				}
			}
		}
		mpf_lastupdate_blink.setValue("(" + kk + " updated..)");
	}
}

class mpfbtnlciker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getTarget();
		mpf_UpdateSingular_listbox(isel);
		//mpfUpdate_specs2(isel);
	}
}
mpfbuttoncliker = new mpfbtnlciker();

void drawAudit_MPF_things()
{
	k9 = "font-size:9px";
	String[] kabom = new String[1];

	Grid igrd = new Grid(); igrd.setSclass("GridLayoutNoBorder");
	org.zkoss.zul.Rows irows = new org.zkoss.zul.Rows();
	irows.setParent(igrd);

	Grid meligrd = new Grid(); meligrd.setSclass("GridLayoutNoBorder");
	org.zkoss.zul.Rows melirows = new org.zkoss.zul.Rows();
	melirows.setParent(meligrd);	

	for(i=0; i<mel_lbl.length; i++)
	{
		try // RW specs MPF
		{
			nrw = new org.zkoss.zul.Row(); nrw.setStyle("background:#3D99AA"); nrw.setParent(irows);
			ngfun.gpMakeLabel(nrw, "", mlbl[i], k9);

			if(mctype[i].equals("lb"))
			{
				klb = new Listbox(); klb.setMold("select"); klb.setStyle(k9);
				klb.setId(mcid[i]); klb.setParent(nrw);

				if(i == 0) // rw grades are live from FC6
				{
					for(d : glob_focus6_grades)
					{
						kabom[0] = d.get("grade");
						if(kabom[0] != null) lbhand.insertListItems(klb,kabom,"false","");
					}
				}
				else
					if(!mclookup[i].equals("")) luhand.populateListbox_ByLookup(klb, mclookup[i], 2);

				klb.setSelectedIndex(0);
			}
			else
			{
				ngfun.gpMakeTextbox(nrw, mcid[i], "", k9, "95%", textboxnulldrop);
			}

			ngfun.gpMakeButton(nrw, mbtn[i], "Upd", k9, mpfbuttoncliker);
		} catch (ArrayIndexOutOfBoundsException e) {}

		try // MEL specs MPF
		{
			melnrw = new org.zkoss.zul.Row(); melnrw.setStyle("background:#E48313"); melnrw.setParent(melirows);
			ngfun.gpMakeLabel(melnrw,"",mel_lbl[i],k9);
			if(melctype[i].equals("lb"))
			{
				klb = new Listbox(); klb.setMold("select"); klb.setStyle(k9);
				klb.setId(melcid[i]); klb.setParent(melnrw);
				if(!melclookup[i].equals("")) luhand.populateListbox_ByLookup(klb, melclookup[i], 2);
				klb.setSelectedIndex(0);
			}
			else
			{
				ngfun.gpMakeTextbox(melnrw, melcid[i], "", k9, "95%", textboxnulldrop);
			}
			ngfun.gpMakeButton(melnrw, melbtn[i], "Upd", k9, mpfbuttoncliker);
		} catch (ArrayIndexOutOfBoundsException e) {}
	}

	igrd.setParent(rw_mpfgridy);
	meligrd.setParent(mel_mpfgridy);
}

