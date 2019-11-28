#pragma  once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include "loadData.h"
#include "BaseInitOp.cuh"
#include "evaluate.cuh"
#include "RemoveOP.cuh"
#include "InsertOp.cuh"
#include "critetionOp.cuh"
#include "OptimalOp.cuh"
#include "loadDataFrame.cuh"
#include "stdlib.h"

#include "process.h"
#include "spyderMetroData.cuh"
#include "Companyfactory.cuh"
#include "curl/curl.h"

#include "request.h"
#include "Dispatch.h"
#include "dispatchTest.cuh"


#include "ALNS.cuh"
#include "Route.cuh"
#include "msgpack.hpp"
#include <sstream>
#include <fstream>




namespace  PDPTW {


	void routeGenerate(vector<PDPTW::company> companys) {

		std::string metro_station_name = "'西兴站'";
		std::string hour_begin = "8";
		std::string hour_end = "9";
		std::string day_begin = "20190301";
		std::string day_end = "20190401";

		//PDPTW::spyder(metro_station_name, hour_begin, hour_end, day_begin, day_end);
		map<int, float> flowPercent = PDPTW::metroFlowDistribution();

		std::vector<PDPTW::CompanyWithTimeTable> companyWithTimeWindows;
		for (int i = 0; i < companys.size(); i++) {
			companyWithTimeWindows.push_back(PDPTW::companyFactory(companys[i], flowPercent));
		}

		//对于不同公司类型生成不同的矩阵用于计算公司类型
		std::string origins = "120.220429,30.187295";
		std::string dest = "120.189549,30.190514";
		std::string name = "西兴";
		PDPTW::CompanyWithTimeTable depot(name, 120.220429, 30.187295, 0, 0, -1);


		std::vector<PDPTW::CompanyWithTimeTable> smallCompanys;
		std::vector<PDPTW::CompanyWithTimeTable> largeCompanys;
		smallCompanys.push_back(depot);
		largeCompanys.push_back(depot);

		for (int i = 0; i < companyWithTimeWindows.size(); i++) {
			if (companyWithTimeWindows[i].companyType == 0) {

				smallCompanys.push_back(companyWithTimeWindows[i]);
			}
			else {
				largeCompanys.push_back(companyWithTimeWindows[i]);
			}
		}

		//初始化距离矩阵以及初始化时间矩阵
		float * smallCompanyDistMatrix = (float*)malloc(smallCompanys.size()*smallCompanys.size() * sizeof(float));
		float * smallCompanyDurationMatrix = (float*)malloc(smallCompanys.size()*smallCompanys.size() * sizeof(float));

		//获取矩阵
		PDPTW::getDistMatrix(smallCompanyDistMatrix, smallCompanyDurationMatrix, smallCompanys);

		float * largeCompanyDistMatrix = (float*)malloc(largeCompanys.size()*smallCompanys.size() * sizeof(float));
		float * largeCompanyDurationMatrix = (float*)malloc(largeCompanys.size()*smallCompanys.size() * sizeof(float));

		//获取矩阵
		PDPTW::getDistMatrix(largeCompanyDistMatrix, largeCompanyDurationMatrix, largeCompanys);




		for (int i = 0; i < largeCompanys.size(); i++) {
			std::cout << i << "  " << largeCompanys[i].name << " ";
		}
		std::cout << std::endl;


		//大公司每个时段的客流

		for (int i = 0; i < 10; i++) {

			for (int j = 1; j < largeCompanys.size(); j++) {

				largeCompanys[j].employeeWantUseBusNum = largeCompanys[j].pipeflow[i].waitDemand;
			}





			int currentBestval = 99999;
			PDPTW::alnsModelOutput bestRes;
			std::vector<PDPTW::Route>  Pool;

			for (int t = 0; t < 10; t++) {

				PDPTW::UserGroup* largeCompanysUsers = NULL;
				largeCompanysUsers = (PDPTW::UserGroup*)malloc(largeCompanys.size() * sizeof(PDPTW::UserGroup));
				companyToUsers(largeCompanysUsers, largeCompanys);
				size_t* largeCompanyUserSize = (size_t*)malloc(sizeof(size_t));
				*largeCompanyUserSize = largeCompanys.size();

				PDPTW::alnsModelOutput res = PDPTW::alnsModel(largeCompanysUsers, largeCompanyUserSize, largeCompanyDistMatrix, largeCompanyDurationMatrix);

				if (res.value < currentBestval) {
					currentBestval = res.value;

					bestRes.host_Route = res.host_Route;
					bestRes.routeCapacity = res.routeCapacity;
					bestRes.routeCount = res.routeCount;
					bestRes.routeNum = res.routeNum;
					bestRes.value = res.value;

				}
				else {

					free(res.host_Route);
					res.host_Route = NULL;

					free(res.routeCapacity);
					res.routeCapacity = NULL;

					free(res.routeCount);
					res.routeCount = NULL;
				}


			}

			std::cout << "best val is: " << currentBestval << std::endl;

			for (int k = 0; k <= bestRes.routeNum; k++) {

				if (bestRes.routeCount[k] == 0) {
					continue;
				}


				PDPTW::Route route(bestRes.host_Route, k, bestRes.routeCount, 0, largeCompanys, largeCompanyDistMatrix, largeCompanyDurationMatrix, largeCompanys.size());
				route.showAll(largeCompanys);
				Pool.push_back(route);


				std::string filename = to_string(i) + "___" + to_string(k) + "___route.text";
				std::ofstream osm(filename);
				if (osm.is_open()) {

					osm << route.nodes.size() << std::endl;
					osm << route.routeDistance << std::endl;
					osm << route.routeSingleDistance << std::endl;
					osm << route.routeDuration << std::endl;
					osm << route.routeSingleDuration << std::endl;
					osm << route.routeType << std::endl;

					for (int pp = 0; pp < route.nodes.size(); pp++) {
						osm << route.nodes[pp].CustomerNodeStationID << " ";
					}
					osm << std::endl;

					for (int pp = 0; pp < route.stationWaitFlow.size(); pp++) {
						osm << route.stationWaitFlow[pp] << "  ";
					}
					osm << std::endl;

					osm.close();


				}


			}


			free(bestRes.host_Route);
			bestRes.host_Route = NULL;

			free(bestRes.routeCapacity);
			bestRes.routeCapacity = NULL;

			free(bestRes.routeCount);
			bestRes.routeCount = NULL;
		}


		//小公司潜在的拼线线路生成

		int currentBestval2 = 99999;
		PDPTW::alnsModelOutput bestRes2;

		for (int i = 0; i < 20; i++) {

			PDPTW::UserGroup* smallCompanyUsers = NULL;
			smallCompanyUsers = (PDPTW::UserGroup*)malloc(smallCompanys.size() * sizeof(PDPTW::UserGroup));
			companyToUsers(smallCompanyUsers, smallCompanys);
			size_t* smallCompanyUserSize = (size_t*)malloc(sizeof(size_t));
			*smallCompanyUserSize = smallCompanys.size();
			PDPTW::alnsModelOutput res = PDPTW::alnsModel(smallCompanyUsers, smallCompanyUserSize, smallCompanyDistMatrix, smallCompanyDurationMatrix);

			if (res.value < currentBestval2) {
				currentBestval2 = res.value;

				bestRes2.host_Route = res.host_Route;
				bestRes2.routeCapacity = res.routeCapacity;
				bestRes2.routeCount = res.routeCount;
				bestRes2.routeNum = res.routeNum;
				bestRes2.value = res.value;

			}
			else {

				free(res.host_Route);
				res.host_Route = NULL;

				free(res.routeCapacity);
				res.routeCapacity = NULL;

				free(res.routeCount);
				res.routeCount = NULL;
			}

		}


		std::cout << "best val is: " << currentBestval2 << std::endl;

		for (int k = 0; k <= bestRes2.routeNum; k++) {

			if (bestRes2.routeCount[k] == 0) {
				continue;
			}


			PDPTW::Route route(bestRes2.host_Route, k, bestRes2.routeCount, 1, smallCompanys, smallCompanyDistMatrix, smallCompanyDurationMatrix, smallCompanys.size());
			route.showAll(smallCompanys);


			std::string filename = "smallCompany___" + to_string(k) + "___route.text";
			std::ofstream osm(filename);
			if (osm.is_open()) {

				osm << route.nodes.size() << std::endl;
				osm << route.routeDistance << std::endl;
				osm << route.routeSingleDistance << std::endl;
				osm << route.routeDuration << std::endl;
				osm << route.routeSingleDuration << std::endl;
				osm << route.routeType << std::endl;

				for (int pp = 0; pp < route.nodes.size(); pp++) {
					osm << route.nodes[pp].CustomerNodeStationID << " ";
				}
				osm << std::endl;

				for (int pp = 0; pp < route.stationWaitFlow.size(); pp++) {
					osm << route.stationWaitFlow[pp] << "  ";
				}
				osm << std::endl;

				osm.close();
			}

		}



	}






}