class nn_driver;

    virtual nn_if vif;
    mailbox mbox;
    nn_trans tr;

  function new(virtual nn_if vif, mailbox mbox);
         tr=new();
        this.vif = vif;
        this.mbox= mbox;
    endfunction

    task run();
       

        forever begin
            mbox.get(tr);


            
            vif.act   <= tr.act;
            vif.wt    <= tr.wt;
            vif.bias  <= tr.bias;
            vif.scale <= tr.scale;
            vif.start <= 1'b1;
            tr.out<=vif.out;
            tr.done<=vif.done;


           #250 vif.start <= 1'b0;

            

            $display("[DRIVER] DUT Output = %0d", vif.out);
            $display("----------------------------------");
        end
    endtask

endclass
