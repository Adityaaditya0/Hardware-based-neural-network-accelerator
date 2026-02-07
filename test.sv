`include "nn_env.sv"

class nn_test;

    virtual nn_if vif;
    nn_env env;

    function new(virtual nn_if vif);
        this.vif = vif;
        env = new(vif);
    endfunction

    task run();
        env.run();
    endtask

endclass
