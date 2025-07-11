/************************************************************************
  
Copyright 2019 - Maven Silicon Softech Pvt Ltd.  
  
www.maven-silicon.com 
  
All Rights Reserved. 
This source code is an unpublished work belongs to Maven Silicon Softech Pvt Ltd. 
It is not to be shared with or used by any third parties who have not enrolled for our paid 
training courses or received any written authorization from Maven Silicon.
  
Filename:       ram_scoreboard.sv
  
Author Name:    Putta Satish

Support e-mail: For any queries, reach out to us on "techsupport_vm@maven-silicon.com" 

Version:	1.0

************************************************************************/
//------------------------------------------
// CLASS DESCRIPTION
//------------------------------------------


	// Extend ram_scoreboard from uvm_scoreboard

	class ram_scoreboard extends uvm_scoreboard;

        // Declare handles for uvm_tlm_analysis_fifos parameterized by read & write transactions as fifo_rdh & fifo_wrh respectively
	//    Hint:  uvm_tlm_analysis_fifo #(read_xtn) fifo_rdh;
	//           uvm_tlm_analysis_fifo #(write_xtn) fifo_wrh;
	
	uvm_tlm_analysis_fifo #(read_xtn) fifo_rdh;
        uvm_tlm_analysis_fifo #(write_xtn) fifo_wrh;



        // Add the following integers for Scoreboard Statistics
  	   // wr_xtns_in : calculates number of write transactions 
 	   // rd_xtns_in : calculates number of read transactions
           // xtns_compared : number of xtns compared
           // xtns_dropped : calculates number of xtns failed
	int  wr_xtns_in, rd_xtns_in , xtns_compared ,xtns_dropped;	
       
	// Factory registration
	 `uvm_component_utils(ram_scoreboard)

	// Declare an Associative array as a reference model 
         	// Type logic [63:0] and index type int

		logic [63:0] ref_data [bit[31:0]];
	// Declare handles of type write_xtn & read_xtn to store the tlm_analysis_fifo data 	
		write_xtn wr_data;
		read_xtn rd_data;

//------------------------------------------
// Methods
//------------------------------------------

// Standard UVM Methods:
extern function new(string name,uvm_component parent);
extern function void mem_write(write_xtn wd);
extern function bit mem_read(ref read_xtn rd);
extern task run_phase(uvm_phase phase);
extern function void check_data(read_xtn rd);
extern function void report_phase(uvm_phase phase);

endclass

//-----------------  constructor new method  -------------------//

       // Add Constructor function
           // Create instances of uvm_tlm_analysis fifos inside the constructor
           // using new("fifo_h", this)
     	function ram_scoreboard::new(string name,uvm_component parent);
		super.new(name,parent);
		 fifo_rdh = new("fifo_rdh", this);
   		 fifo_wrh= new("fifo_wrh", this);
	endfunction

        
//-----------------  mem_write() method  -------------------//

	 //Explore mem_write method 
  	 //method to write write_xtn into ref model
	 function void ram_scoreboard::mem_write(write_xtn wd);
	     if(wd.write)
        `uvm_info("MEM Write Function", $psprintf("Address = %h", wd.address), UVM_LOW)
	     begin
     	ref_data[wd.address] = wd.data;
      	`uvm_info(get_type_name(), $sformatf("Write Transaction from Write agt_top \n %s",wd.sprint()), UVM_HIGH)
        wr_xtns_in ++;
     	end
   	endfunction : mem_write
	

//-----------------  mem_read() method  -------------------//

  	
     	//Explore mem_read method 
      	//method to read read_xtn from ref model
      function bit ram_scoreboard::mem_read(ref read_xtn rd);
       	if(rd.read)
      	 begin
      	`uvm_info(get_type_name(), $sformatf("Read Transaction from Read agt_top \n %s",rd.sprint()), UVM_HIGH)
        `uvm_info("MEM Function", $psprintf("Address = %h", rd.address), UVM_LOW)
        
      	if(ref_data.exists(rd.address))
      	begin
        rd.data = ref_data[rd.address] ;
        rd_xtns_in ++;
        return(1);
      	end
      	else
      	begin
        xtns_dropped ++;
        return(0);
        end				      
        end
  	endfunction : mem_read  


//-----------------  run() phase  -------------------//

       task ram_scoreboard::run_phase(uvm_phase phase);
         fork
// In forever loop
// get and print the write data using the tlm fifo
// Call the method mem_write

	   forever begin
            fifo_wrh.get(wr_data);
             mem_write(wr_data);
             `uvm_info("WRITE SB","write data" , UVM_LOW)
              wr_data.print; end
// In forever loop
// get and print the read data using the tlm fifo
// Call the method check_data

           forever begin
            fifo_rdh.get(rd_data);
             `uvm_info("READ SB", "read data" , UVM_LOW)
              rd_data.print;
             check_data(rd_data); end
         join
       endtask

      	

	  //Explore method check_data 
       function void ram_scoreboard::check_data(read_xtn rd);
      	read_xtn ref_xtn;
      	// Copy of read XTN
      	$cast( ref_xtn, rd.clone());
      	// Update transaction handle to compared by calling read method of ref_data mem_read(ref_xtn);
   	   `uvm_info(get_type_name(), $sformatf("Read Transaction from Memory_Model \n %s",ref_xtn.sprint()), UVM_HIGH)
        if(mem_read(ref_xtn))
		begin
       		//compare
  		if(rd.compare(ref_xtn))
		begin
	 	`uvm_info(get_type_name(), $sformatf("Scoreboard - Data Match successful"), UVM_MEDIUM)
	 	 xtns_compared++ ;
        	end
        	else	
	  	`uvm_error(get_type_name(), $sformatf("\n Scoreboard Error [Data Mismatch]: \n Received Transaction:\n %s \n Expected Transaction: \n %s", 
                                  rd.sprint(), ref_xtn.sprint()))
  		end
       	else
          	uvm_report_info(get_type_name(), $psprintf("No Data written in the address=%d \n %s",rd.address, rd.sprint()));

	endfunction


    function void ram_scoreboard::report_phase(uvm_phase phase);
   // Displays the final report of test using scoreboard stistics
   `uvm_info(get_type_name(), $sformatf("MSTB: Simulation Report from ScoreBoard \n Number of Read Transactions from Read agt_top : %0d \n Number of Write Transactions from write agt_top : %0d \n Number of Read Transactions Dropped : %0d \n Number of Read Transactions compared : %0d \n\n",rd_xtns_in, wr_xtns_in, xtns_dropped, xtns_compared), UVM_LOW)
 endfunction 







      

   
