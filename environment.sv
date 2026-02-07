`include "nn_generator.sv"
`include "nn_driver.sv"

class nn_env;

    nn_generator gen;
    nn_driver    drv;
    mailbox mbox;
    virtual nn_if vif;
    function new(virtual nn_if vif);
        this.vif = vif;

        mbox = new();

      gen = new(mbox);
      drv = new(vif, mbox);
    endfunction

    task run();
        fork
            gen.run(10);   // generate 10 random tests
            drv.run();     // drive DUT for all tests
        join
    endtask

endclass
