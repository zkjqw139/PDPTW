#pragma  once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cublas.h>
#include <string>
#include <map>
#include <deque>

namespace PDPTW {

	struct stationNode {
		int timeid;
		int waitDemand;
	};  

	bool compareStationNode(stationNode& a, stationNode & b) {
		return a.timeid < b.timeid;
	}

	struct busNode {

		//当前车辆的发车时间
		//当前车辆的最大载客辆
		//当前车辆期望的里程数目
		int  arrivetime;
		int  busDemand;
		int  currentDemand = 0;
		int  TravelDistance;
		bool isLast;
	};

	bool compareBusNode(busNode& a, busNode & b) {
		return a.arrivetime < b.arrivetime;
	}

	class company {


	public:
		company() {

			name = "异世界 ";
			lon = 0.0;
			lat = 0.0;
			employeeNum = 9999999;
			employeeWantUseBusNum = 0;
		}


		company(std::string name, float lon, float lat, int employeeNum, int employeeWantUseBusNum) {

			this->name = name;
			this->lon = lon;
			this->lat = lat;
			this->employeeNum = employeeNum;
			this->employeeWantUseBusNum = employeeWantUseBusNum;
		}


		std::string  name;
		float        lon;
		float        lat;
		int          employeeNum;
		int          employeeWantUseBusNum;

	};


	class CompanyWithTimeTable:public company {

		  
	public:

		CompanyWithTimeTable(std::string name, float lon,float lat, int employeenum, int employeeWantUseBuSNum,int companyType) {

			this->name = name;
			this->lon  = lon;
			this->lat  = lat;
			this->employeeNum = employeenum;
			this->employeeWantUseBusNum = employeeWantUseBuSNum;
			this->companyType = companyType;
		}


		int companyType;                              //表示公司类型，分为大公司，中型公司，以及小公司
 		std::map<int, int> timeflow;                  //时刻表表示每五分钟到达的用户
		                                              //用字典表示用户到达率
		std::map<int, int>  DemandInStation;          //表示每一个时刻在现有站点上等待的用户
		 
		std::deque<stationNode> pipeflow;             //用户水管，用以计算代价函数
	};

	struct station {
		std::string name;
		std::deque<int> flow;
		int companyType;

		station(std::string name, std::deque<int> flow, int companyType) {

			this->name = name;
			this->flow = flow;
			this->companyType = companyType;

		}

		void show() {

			std::cout << this->name << std::endl;
			std::cout << this->companyType << std::endl;

			for (int i = 0; i < this->flow.size(); i++) {
				std::cout << this->flow[i] << " ";
			}
			std::cout << std::endl;

		}


	};

}




