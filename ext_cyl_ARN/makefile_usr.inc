$(OBJDIR)/frame.o           :frame.f;                                $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/mntrlog_block.o   :mntrlog_block.f MNTRLOGD;               $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/mntrlog.o         :mntrlog.f MNTRLOGD;                     $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/mntrtmr_block.o   :mntrtmr_block.f MNTRLOGD MNTRTMRD;      $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/mntrtmr.o         :mntrtmr.f MNTRLOGD MNTRTMRD FRAMELP;    $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/rprm_block.o      :rprm_block.f RPRMD;                     $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/rprm.o            :rprm.f RPRMD FRAMELP;                   $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/math_tools.o      :math_tools.f;                           $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/spongebx.o        :spongebx.f SPONGEBXD;                   $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/io_tools_block.o  :io_tools_block.f IOTOOLD;               $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/io_tools.o        :io_tools.f IOTOOLD;                     $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/chkpoint.o        :chkpoint.f CHKPOINTD;                   $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/chkptd.o          :chkptd.f CHKPOINTD;                     $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/tstepper.o        :tstepper.f TSTEPPERD;                   $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/conht_tools.o     :conht_tools.f CONHTD;                   $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/arn_arp.o         :arn_arp.f ARN_ARPD TSTEPPERD;           $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/arn_arp_io.o      :arn_arp_io.f ARN_ARPD TSTEPPERD;        $(F77) -c $(FL2) -I./ $< -o $@
