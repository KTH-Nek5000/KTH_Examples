$(OBJDIR)/frame.o           :$(FRAME_SRC)/frame.f;                   $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/mntrlog_block.o   :$(MONITOR_SRC)/mntrlog_block.f;         $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/mntrlog.o         :$(MONITOR_SRC)/mntrlog.f;               $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/mntrtmr_block.o   :$(MONITOR_SRC)/mntrtmr_block.f;         $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/mntrtmr.o         :$(MONITOR_SRC)/mntrtmr.f;               $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/rprm_block.o      :$(RUNPARAM_SRC)/rprm_block.f;           $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/rprm.o            :$(RUNPARAM_SRC)/rprm.f;                 $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/io_tools_block.o  :$(IO_TOOLS_SRC)/io_tools_block.f;       $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/io_tools.o        :$(IO_TOOLS_SRC)/io_tools.f;             $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/chkpoint.o        :$(CHKPT_SRC)/chkpoint.f;                $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/chkptd.o          :$(CHKPTDMM_SRC)/chkptd.f;               $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/math_tools.o      :$(MATH_SRC)/math_tools.f;               $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/spongebx.o        :$(SPONGE_BOX_SRC)/spongebx.f;           $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/tstepper.o        :${TSTEPPER_SRC}/tstepper.f;             $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/conht_tools.o     :${CONHT_SRC}/conht_tools.f;             $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/arn_arp.o         :${ARNARP_SRC}/arn_arp.f ./ARN_ARPD;     $(F77) -c $(FL2) $< -o $@
$(OBJDIR)/arn_arp_io.o      :${ARNARP_SRC}/arn_arp_io.f ./ARN_ARPD;  $(F77) -c $(FL2) $< -o $@
