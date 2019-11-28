#pragma  once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <vector>
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cublas.h>
#include "CustomerNode.cuh"
#include "Company.cuh"

namespace PDPTW {

	
	struct RouteSample {

		int waitTime;
		int nodeDemand;


	};


	class Route {
	
	public:
		std::vector<PDPTW::CustomerNode>  nodes; //线路上所有需要到达的站点
		std::vector<int>   nodeIDs;              //线路上的所有ID
		
		 
		int  routeCount;                         //当前线路经过的公司数目
		int  routeDistance;                      //线路里程数
		int  routeSingleDistance;

		int  routeDuration;                      //线路行驶时间
		int  routeSingleDuration;

		
		int  routeType;                          //type 0:高频率频繁发车
		                                         //type 1:定时发车

		int  routeID;                            //为每条线路生成一个独一无二的哈希值方便检索
		int  timeid;

		std::vector<int>  stationWaitFlow;
		std::vector<RouteSample> waitQeue;       //等待客流的排队序列

		std::map<int, float> companyPercent;     //各个公司所占的客流百分比


		//矩阵访问特性
		int maxRouteCounts = 64;
		int maxUserSize = 128;
		
		Route(std::vector<int> nodeIDs, int routeCount, int routeDistance, int routeSingleDistance, int routeDuration, int routeSingleDuration, int routeType,  std::vector<int> stationWaitFlow,int timeid) {

			this->nodeIDs       = nodeIDs;
			this->routeCount    = routeCount;
			this->routeDistance = routeDistance;
			this->routeDuration = routeDuration;
			this->routeSingleDuration = routeSingleDuration;
			this->routeSingleDistance = routeSingleDistance;
			this->routeType = routeType;
			this->stationWaitFlow = stationWaitFlow;
			this->timeid = timeid;
		}

		void readShow() {

			for (int i = 0; i < nodeIDs.size(); i++) {
				std::cout << "    " << nodeIDs[i] << "   " ;
			}
			std::cout << std::endl;
			std::cout << "this route Type is: " << this->routeType << std::endl;
			std::cout << "route distamce is: " << this->routeDistance << std::endl;
			std::cout << "single route distamce is: " << this->routeSingleDistance << std::endl;
			std::cout << "route duration is: " << this->routeDuration << std::endl;
			std::cout << "single route duration is: " << this->routeSingleDuration << std::endl;
			std::cout << "time id is: " << this->timeid << std::endl;
			std::cout << "show every time id wait flow" << std::endl;
			for (int i = 0; i < this->stationWaitFlow.size(); i++) {
				std::cout << " " << stationWaitFlow[i];
			}
			std::cout << std::endl;




		}


		Route(CustomerNode* Route,  int routeID, int* routeCount, int routeType, std::vector<PDPTW::CompanyWithTimeTable> Companys,float * largeCompanyDistMatrix, float * largeCompanyDurationMatrix, int size) {

			for (int i = 0; i < routeCount[routeID]; i++) {
				nodes.push_back(Route[this->maxUserSize * routeID + i]);
			}
		
			this->routeType = routeType;
			this->getRouteDistance(largeCompanyDistMatrix, size);
			this->getRouteDuration(largeCompanyDurationMatrix, size);
			this->getSingleRouteDistance(largeCompanyDistMatrix, size);
			this->getSingleRouteDuration(largeCompanyDurationMatrix, size);
			this->getStationWaitFlow(Companys);
		};

		
		//显示当前线路经过的各个站点
		void show(std::vector<PDPTW::CompanyWithTimeTable> Companys) {
			for (int i = 0; i < nodes.size(); i++) {
				std::cout <<"    "<< nodes[i].CustomerNodeStationID+1<<"   "<< Companys[nodes[i].CustomerNodeStationID].name;
			}
			std::cout << std::endl;
		}

		//显示当前线路经过的各个站点，并且显示所有的状态
		void showAll(std::vector<PDPTW::CompanyWithTimeTable> Companys) {

			for (int i = 0; i < nodes.size(); i++) {
				std::cout << "    " << nodes[i].CustomerNodeStationID + 1 << "   " << Companys[nodes[i].CustomerNodeStationID].name;
			}
			std::cout << std::endl;
			std::cout << "this route Type is: " << this->routeType << std::endl;
			std::cout << "route distamce is: " << this->routeDistance << std::endl;
			std::cout << "single route distamce is: " << this->routeSingleDistance << std::endl;
			std::cout << "route duration is: " << this->routeDuration << std::endl;
			std::cout << "single route duration is: " << this->routeSingleDuration << std::endl;

			std::cout << "show every time id wait flow" << std::endl;
			for (int i = 0; i < this->stationWaitFlow.size(); i++) {
				std::cout << " " << stationWaitFlow[i];
			}
			std::cout << std::endl;

		}


		//判断这家公司是否在线路上
		bool checkCompany(int companyID) {

			bool isin = false;

			for (int i = 0; i < this->nodeIDs.size(); i++) {

				if (this->nodeIDs[i] == companyID) {
					isin = true;
				}
			}

			return isin;
		};

		//计算线路上各个公司占的流量比
		void setComapnyPercent(std::vector<PDPTW::company> companys) {

			int sum = 0;

			for (int i = 0; i < nodeIDs.size(); i++) {

				sum = sum + companys[nodeIDs[i]].employeeWantUseBusNum;

			}


			for (int i = 0; i < nodeIDs.size(); i++) {

				float percent = float(companys[nodeIDs[i]].employeeWantUseBusNum) / float(sum);
				//std::cout << percent << "  ";
				this->companyPercent.insert(std::pair<int, float>(nodeIDs[i], percent));

			}
			//std::cout << std::endl;
			

		}

		




	private:

		//获取当前路线的距离
		void getRouteDistance(float * largeCompanyDistMatrix,int size) {

			int dist = 0;

			dist = dist + largeCompanyDistMatrix[nodes[0].CustomerNodeStationID];

			for (int i = 1; i < nodes.size(); i++) {

				dist = dist + largeCompanyDistMatrix[nodes[i - 1].CustomerNodeStationID*size + nodes[i].CustomerNodeStationID];
			}
			
			dist = dist+ largeCompanyDistMatrix[nodes[nodes.size()-1].CustomerNodeStationID];
			
			this->routeDistance = dist;
		}

		//获取当前路线的行驶时间
		void getRouteDuration(float * largeCompanyDurationMatrix, int size) {

			int duration = 0;

			duration = duration + largeCompanyDurationMatrix[nodes[0].CustomerNodeStationID];

			for (int i = 1; i < nodes.size(); i++) {

				duration = duration + largeCompanyDurationMatrix[nodes[i - 1].CustomerNodeStationID*size + nodes[i].CustomerNodeStationID];
			}

			duration = duration + largeCompanyDurationMatrix[nodes[nodes.size() - 1].CustomerNodeStationID];

			this->routeDuration = duration;

		}

        //获取当前路线的不回厂的行驶距离
		void getSingleRouteDistance(float * largeCompanyDistMatrix, int size) {

			int dist = 0;

			dist = dist + largeCompanyDistMatrix[nodes[0].CustomerNodeStationID];

			for (int i = 1; i < nodes.size(); i++) {

				dist = dist + largeCompanyDistMatrix[nodes[i - 1].CustomerNodeStationID*size + nodes[i].CustomerNodeStationID];
			}

			this->routeSingleDistance = dist;
		}

		//获取当前路线的不回厂的行驶时间
		void getSingleRouteDuration(float * largeCompanyDurationMatrix, int size) {
			
			int duration = 0;

			duration = duration + largeCompanyDurationMatrix[nodes[0].CustomerNodeStationID];

			for (int i = 1; i < nodes.size(); i++) {

				duration = duration + largeCompanyDurationMatrix[nodes[i - 1].CustomerNodeStationID*size + nodes[i].CustomerNodeStationID];
			}

			 
			this->routeSingleDuration = duration;
		}

		//获取在每个决策时刻点站点的等待的用户数目
		void getStationWaitFlow(std::vector<PDPTW::CompanyWithTimeTable> Companys) {

			for (int i = 0; i < 30; i++) {
				stationWaitFlow.push_back(0);
			}

			for (int i = 0; i < nodes.size(); i++) {

				int nodeID = nodes[i].CustomerNodeStationID;
				int ind = 0;
				for (int j = 0; j < Companys[nodeID].pipeflow.size();j++) {
                    
					if (j % 2 == 0) {
						stationWaitFlow[ind] += (Companys[nodeID].pipeflow[j].waitDemand) / 2;
						stationWaitFlow[ind + 1] += (Companys[nodeID].pipeflow[j].waitDemand) / 2;
					}
					else {
						stationWaitFlow[ind] += (Companys[nodeID].pipeflow[j].waitDemand- Companys[nodeID].pipeflow[j-1].waitDemand) / 2;
						stationWaitFlow[ind + 1] += (Companys[nodeID].pipeflow[j].waitDemand- Companys[nodeID].pipeflow[j-1].waitDemand) / 2;
					}

					ind += 2;
				}
			}


			for (int i = 1; i < stationWaitFlow.size(); i++) {
				stationWaitFlow[i] = stationWaitFlow[i] + stationWaitFlow[i- 1];
			}
		}    
	};


    
	//备选线路的集合
	class RoutePool {

		std::vector<Route>  Pool;                  //线路池
		std::vector<bool>   action;                //备选行为列表
		std::vector<std::vector<int>>  flowMatrix; //流量矩阵


        
		RoutePool() {

		}


		void showAllRoute(std::vector<company> companys) {


			//显示当前各个线路的客流
			for (int i = 0; i < Pool.size(); i++) {

				//显示当前线路的线路编号
				std::cout << "当前线路编号是： " << i << std::endl;
				//显示当前线路经过的站点
				std::vector<int> NodeNames = Pool[i].nodeIDs;

				for (int t = 0; t < NodeNames.size(); t++) {

					int id = NodeNames[t];
					std::cout << companys[id].name << "  ";
				}
				std::cout << std::endl;

				//显示当前线路的正在等待客流

				for (int t = 0; t < Pool[i].stationWaitFlow.size(); t++) {
					std::cout << Pool[i].stationWaitFlow[t] << "  ";
				}
				std::cout << std::endl;



			}

		}


		~RoutePool() {

		}


	};



}