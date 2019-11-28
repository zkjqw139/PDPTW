#pragma once
#include "curl/curl.h"
#include "cjson\cJSON.h"
#include <iostream>
#include <stdio.h>
#include <vector>
#include <algorithm>
#include <time.h>
#include <iostream>
#include "DFSOP.cuh"
#include "request.h"
#include "evaluate.cuh"


namespace PDPTW {

	void dispatchToArriveTimeTableTest(std::vector<PDPTW::CompanyWithTimeTable> CompanyWithTimeTables) {
		
		int a[19]        = { 0 ,  0,   1,  0,  1,   0,   1,   0,   1,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0 };
		int duration[19] = { 300,450,600,750,900,1050,1200,1350,1500,1650,1800,1950,2100,2250,2400,2550,2700,2850,3000 };

		std::vector<PDPTW::dfsComponent> dispatchTable;
		for (int i = 0; i < 19; i++) {

			PDPTW::dfsComponent dfscomp;
			dfscomp.DispatchTime = duration[i];

			if (a[i] == 0) {
				dfscomp.ifDispatch = false;
			}
			else {
				dfscomp.ifDispatch = true;
			}

			dispatchTable.push_back(dfscomp);
		}


		std::string origins = "120.203149,30.183442";
		std::string dest = "120.189549,30.190514";
		PDPTW::disInfo dinfo = PDPTW::getAllDistanceAndDuration(origins, dest);


		clock_t startTime, endTime;
		startTime = clock();
		std::vector<PDPTW::busNode> res = dispatchToArriveTimeTable(dispatchTable, dinfo);

		std::cout << CompanyWithTimeTables[13].name << std::endl;

		std::deque<PDPTW::stationNode> pipeflow = CompanyWithTimeTables[13].pipeflow;

		for (int i = 0; i < pipeflow.size(); i++) {
			std::cout << pipeflow[i].waitDemand << " ";
		}
		std::cout << std::endl;

		float cost = PDPTW::freqEvaluate(pipeflow, res, dinfo);

		std::cout << "cost is: " << cost << std::endl;
		endTime = clock();




		for (int i = 0; i < res.size(); i++) {
			std::cout << res[i].arrivetime << " " << res[i].TravelDistance << " " << res[i].busDemand << " " << res[i].isLast << std::endl;
		}


		std::cout << std::endl;
		std::cout << "Totle Time : " << (double)(endTime - startTime) / CLOCKS_PER_SEC << "s" << std::endl;
	}
}