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
		std::vector<PDPTW::CustomerNode>  nodes; //��·��������Ҫ�����վ��
		std::vector<int>   nodeIDs;              //��·�ϵ�����ID
		
		 
		int  routeCount;                         //��ǰ��·�����Ĺ�˾��Ŀ
		int  routeDistance;                      //��·�����
		int  routeSingleDistance;

		int  routeDuration;                      //��·��ʻʱ��
		int  routeSingleDuration;

		
		int  routeType;                          //type 0:��Ƶ��Ƶ������
		                                         //type 1:��ʱ����

		int  routeID;                            //Ϊÿ����·����һ����һ�޶��Ĺ�ϣֵ�������
		int  timeid;

		std::vector<int>  stationWaitFlow;
		std::vector<RouteSample> waitQeue;       //�ȴ��������Ŷ�����

		std::map<int, float> companyPercent;     //������˾��ռ�Ŀ����ٷֱ�


		//�����������
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

		
		//��ʾ��ǰ��·�����ĸ���վ��
		void show(std::vector<PDPTW::CompanyWithTimeTable> Companys) {
			for (int i = 0; i < nodes.size(); i++) {
				std::cout <<"    "<< nodes[i].CustomerNodeStationID+1<<"   "<< Companys[nodes[i].CustomerNodeStationID].name;
			}
			std::cout << std::endl;
		}

		//��ʾ��ǰ��·�����ĸ���վ�㣬������ʾ���е�״̬
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


		//�ж���ҹ�˾�Ƿ�����·��
		bool checkCompany(int companyID) {

			bool isin = false;

			for (int i = 0; i < this->nodeIDs.size(); i++) {

				if (this->nodeIDs[i] == companyID) {
					isin = true;
				}
			}

			return isin;
		};

		//������·�ϸ�����˾ռ��������
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

		//��ȡ��ǰ·�ߵľ���
		void getRouteDistance(float * largeCompanyDistMatrix,int size) {

			int dist = 0;

			dist = dist + largeCompanyDistMatrix[nodes[0].CustomerNodeStationID];

			for (int i = 1; i < nodes.size(); i++) {

				dist = dist + largeCompanyDistMatrix[nodes[i - 1].CustomerNodeStationID*size + nodes[i].CustomerNodeStationID];
			}
			
			dist = dist+ largeCompanyDistMatrix[nodes[nodes.size()-1].CustomerNodeStationID];
			
			this->routeDistance = dist;
		}

		//��ȡ��ǰ·�ߵ���ʻʱ��
		void getRouteDuration(float * largeCompanyDurationMatrix, int size) {

			int duration = 0;

			duration = duration + largeCompanyDurationMatrix[nodes[0].CustomerNodeStationID];

			for (int i = 1; i < nodes.size(); i++) {

				duration = duration + largeCompanyDurationMatrix[nodes[i - 1].CustomerNodeStationID*size + nodes[i].CustomerNodeStationID];
			}

			duration = duration + largeCompanyDurationMatrix[nodes[nodes.size() - 1].CustomerNodeStationID];

			this->routeDuration = duration;

		}

        //��ȡ��ǰ·�ߵĲ��س�����ʻ����
		void getSingleRouteDistance(float * largeCompanyDistMatrix, int size) {

			int dist = 0;

			dist = dist + largeCompanyDistMatrix[nodes[0].CustomerNodeStationID];

			for (int i = 1; i < nodes.size(); i++) {

				dist = dist + largeCompanyDistMatrix[nodes[i - 1].CustomerNodeStationID*size + nodes[i].CustomerNodeStationID];
			}

			this->routeSingleDistance = dist;
		}

		//��ȡ��ǰ·�ߵĲ��س�����ʻʱ��
		void getSingleRouteDuration(float * largeCompanyDurationMatrix, int size) {
			
			int duration = 0;

			duration = duration + largeCompanyDurationMatrix[nodes[0].CustomerNodeStationID];

			for (int i = 1; i < nodes.size(); i++) {

				duration = duration + largeCompanyDurationMatrix[nodes[i - 1].CustomerNodeStationID*size + nodes[i].CustomerNodeStationID];
			}

			 
			this->routeSingleDuration = duration;
		}

		//��ȡ��ÿ������ʱ�̵�վ��ĵȴ����û���Ŀ
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


    
	//��ѡ��·�ļ���
	class RoutePool {

		std::vector<Route>  Pool;                  //��·��
		std::vector<bool>   action;                //��ѡ��Ϊ�б�
		std::vector<std::vector<int>>  flowMatrix; //��������


        
		RoutePool() {

		}


		void showAllRoute(std::vector<company> companys) {


			//��ʾ��ǰ������·�Ŀ���
			for (int i = 0; i < Pool.size(); i++) {

				//��ʾ��ǰ��·����·���
				std::cout << "��ǰ��·����ǣ� " << i << std::endl;
				//��ʾ��ǰ��·������վ��
				std::vector<int> NodeNames = Pool[i].nodeIDs;

				for (int t = 0; t < NodeNames.size(); t++) {

					int id = NodeNames[t];
					std::cout << companys[id].name << "  ";
				}
				std::cout << std::endl;

				//��ʾ��ǰ��·�����ڵȴ�����

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