#pragma  once
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cublas.h>
#include <string>
#include <algorithm>
#include <map>
#include "Dispatch.h"
 


namespace PDPTW{



	//对于发车频率
	//使用深度优先搜索来解决
    
	int  DFSbestcost = 99999;
	int  DFSbestResult[16] = { 0 };

	__host__ void DFS(int Res[],int ID,int count,int maxCount,int maxID,PDPTW::disInfo dinfo, std::deque<PDPTW::stationNode> pipeflow){

		
		 
		if (count >= maxCount || ID >= maxID) {
			
			//判断当前解是否是最佳解
			int duration[19] = { 300,450,600,750,900,1050,1200,1350,1500,1650,1800,1950,2100,2250,2400,2550,2700,2850,3000 };


			std::vector<PDPTW::dfsComponent> dispatchTable;
			for (int i = 0; i < 19; i++) {

				PDPTW::dfsComponent dfscomp;
				dfscomp.DispatchTime = duration[i];

				if (Res[i] == 0) {
					dfscomp.ifDispatch = false;
				}
				else {
					dfscomp.ifDispatch = true;
				}

				dispatchTable.push_back(dfscomp);
			}

			std::vector<PDPTW::busNode> res = PDPTW::dispatchToArriveTimeTable(dispatchTable, dinfo);
			float cost = PDPTW::freqEvaluate(pipeflow, res, dinfo);
		    
		 
			std::cout << cost << std::endl;
			for (int i = 0; i < 19; i++) {
				std::cout << Res[i] << " ";
			}
			std::cout << std::endl;
		 
			
			if (cost < DFSbestcost && count>=1) {
				DFSbestcost = cost;
				
				for (auto i = 0; i < 19;i++) {
					DFSbestResult[i] = Res[i];
				}
				
			}
			 

			return;
		}
		
 
		Res[ID] = 0;
		int nextID = ID + 1;
		DFS(Res, nextID,count, maxCount, maxID, dinfo, pipeflow);
		 
		Res[ID] = 1;
	    nextID = ID + 1;
		count = count + 1;
		DFS(Res, nextID, count, maxCount, maxID, dinfo, pipeflow);

		Res[ID] = 0;
		count   = count - 1;

		return;

	}


	__host__ void dfsTest(std::vector<PDPTW::CompanyWithTimeTable> CompanyWithTimeTables) {
	 
		int Res[19] = { 1 ,  0,   0,  0,  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 };
		int maxCount = 5;
		int count = 0;
		int ID = 0;

		std::string origins = "120.203149,30.183442";
		std::string dest = "120.189549,30.190514";
		PDPTW::disInfo dinfo = PDPTW::getAllDistanceAndDuration(origins, dest);
		std::deque<PDPTW::stationNode> pipeflow = CompanyWithTimeTables[13].pipeflow;
		DFS(Res, ID, count, maxCount, 19,dinfo,pipeflow);
	    
		std::cout << DFSbestcost << std::endl;
		for (int i = 0; i < 19; i++) {
			std::cout << DFSbestResult[i] << " ";
		}
		std::cout << std::endl;

	}


}