$(OBJDIR)/math_tools.o        :math_tools.f;         $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/runparam.o              :runparam.f;                          $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/spongebx.o        :spongebx.f;         $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/noisebx.o               :noisebx.f;                           $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/io_tools_block.o  :io_tools_block.f;   $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/io_tools.o        :io_tools.f;         $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/chkpoint.o             :chkpoint.f;                         $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/chkpt_mstp.o        :chkpt_mstp.f;                 $(F77) -c $(FL2) -I./ $< -o $@
