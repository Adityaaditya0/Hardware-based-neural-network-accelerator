`include "nn_trans.sv"

class nn_generator;
      nn_trans tr;
      mailbox mbox;

  function new(mailbox mbox);
        this.mbox = mbox;
    endfunction

    task run(int count = 10);
        

        // Generate randomized input transactions
        repeat (count) begin
            tr = new();
            assert(tr.randomize());

            $display("\n[GENERATOR] Random Inputs Generated");
            $display("ACT   = %p", tr.act);
            $display("WT    = %p", tr.wt);
            $display("BIAS  = %0d", tr.bias);
            $display("SCALE = %0d", tr.scale);

            mbox.put(tr);
        end

        // END-OF-TEST marker
        
    endtask

endclass
