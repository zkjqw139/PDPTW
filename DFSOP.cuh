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
 



	__host__ int * DFS(int Res[],int ID,int count,int maxCount,int maxID,PDPTW::disInfo dinfo, std::deque<PDPTW::stationNode> pipeflow, int &bestcost , int * bestRes){

		
		 
		if (count >= maxCount || ID >= maxID) {
			
			//判断当前解是否是最佳解
			int duration[21] = { 300,450,600,750,900,1050,1200,1350,1500,1650,1800,1950,2100,2250,2400,2550,2700,2850,3000};


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
		    
			 

			if (cost < bestcost && count>=1) {
				bestcost = cost;
				std::memcpy(bestRes,Res, 19 * sizeof(int));
			}
			
			


			return bestRes;
		}
		
 
		Res[ID] = 0;
		int nextID = ID + 1;
		bestRes = DFS(Res, nextID,count, maxCount, maxID, dinfo, pipeflow, bestcost, bestRes);
		 
		Res[ID] = 1;
	    nextID = ID + 1;
		count = count + 1;
		bestRes = DFS(Res, nextID, count, maxCount, maxID, dinfo, pipeflow, bestcost, bestRes);

		Res[ID] = 0;
		count   = count - 1;

	 

		return bestRes;

	}
}