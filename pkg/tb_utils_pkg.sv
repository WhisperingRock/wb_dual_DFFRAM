`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2026 06:38:30 PM
// Design Name: 
// Module Name: tb_utils_pkg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

package tb_utils_pkg;

    /*
        Class testcase
        
        - Purpose : track test number and number of errors
    
    
    */
    class testcase;
        // ~~ attributes ~~
        int unsigned err_cnt;
        int unsigned testnum;
        
        // ~~ constructors ~~
        function new();
            this.err_cnt = 0;
            this.testnum = 0;
        endfunction
        
        // ~~ methods ~~
        function void new_test(input string mes);
            this.testnum = this.testnum + 1;
            this.err_cnt = 0;
            $display("\nStarting TC%0d : %s", this.testnum, mes);
        endfunction
        
        function void err(input string mes); 
            this.err_cnt = this.err_cnt + 1; 
            $display("|\t\tERROR: %s", mes);
        endfunction: err 

        function void test_done();
            if(err_cnt > 0) begin
                $display("TC%0d complete : %0d ERRORS\n", this.testnum, this.err_cnt);
            end
            
            else begin
                $display("TC%0d complete : SUCCESS\n", this.testnum);
            end
        endfunction
        
        function int get_testnum();
            return this.testnum; 
        endfunction
        
        function void print_subtest(input string mes);
            $display("|-%s", mes);
        endfunction
        
    endclass
    
endpackage