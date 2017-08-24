$(OBJDIR)/runparam.o        :runparam.f;                   $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/io_tools_block.o  :io_tools_block.f;             $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/io_tools.o        :io_tools.f;                   $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/chkpoint.o        :chkpoint.f CHKPOINTD;         $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/chkpt_mstp.o      :chkpt_mstp.f CHKPTMSTPD;      $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/sfd.o             :sfd.f SFD;                    $(F77) -c $(FL2) $< -o $@
