#pragma  once
#include "coeff.cuh"
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <time.h>
#include "Company.cuh"
#include "Dispatch.h"

namespace PDPTW {

	//�����Ľ����⺯��
	//ֻ�����ܵ���̳���
	//cpu�汾

	__host__ float BaseEvaluate(CustomerNode* Route,size_t* UserSize,float *DistMatrix,int routeNum,int* routeCount) {
		
		float solutionValue = 0;
		
		int i = 0;
		int j = 0;

		for (i = 0; i <= routeNum; i++) {
			

			float dis = 0;

			if (routeCount[i] == 0) {
				continue;
			}


			dis += DistMatrix[Route[i*PDPTW::maxUserSize].CustomerNodeStationID];
			for (j = 0; j < routeCount[i]-1; j++) {

				int currentID =  Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID;
				int nextID    =  Route[i*PDPTW::maxUserSize + j + 1].CustomerNodeStationID;
				dis           += DistMatrix[currentID*(*UserSize) + nextID];
			}
			dis += DistMatrix[Route[i*PDPTW::maxUserSize+j+1].CustomerNodeStationID];

			 
			solutionValue += (dis / 1000.0)*2.296 + 83;


		}
             
		return solutionValue;

	}


	__host__ float BaseEvaluateSingleRoute(CustomerNode* Route, size_t* UserSize, float *DistMatrix, int routeNum, int* routeCount ,int sepecificRouteNum) {

		int  i = sepecificRouteNum;
		int  j = 0;
		float solutionValue = 0;
		solutionValue += DistMatrix[Route[i*PDPTW::maxUserSize].CustomerNodeStationID];
		for (j = 0; j < routeCount[i] - 1; j++) {

			int currentID = Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID;
			int nextID = Route[i*PDPTW::maxUserSize + j + 1].CustomerNodeStationID;
			solutionValue += DistMatrix[currentID*(*UserSize) + nextID];
		}
		solutionValue += DistMatrix[Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID];

		return solutionValue;

	}


	__host__ float baseSingleEvaluate(CustomerNode* route, size_t* UserSize, float *DistMatrix, int routeCount) {
		
		 
		int  j = 0;
		float solutionValue = 0;	
		
		if (routeCount == 0) {
			return 0;
		}

		solutionValue += DistMatrix[route[0].CustomerNodeStationID];

	
		for (j = 0; j < routeCount - 1; j++) {
				//printf("%d \n", j);
				int currentID = route[j].CustomerNodeStationID;
				int nextID = route[j + 1].CustomerNodeStationID;


				solutionValue += DistMatrix[currentID*(*UserSize) + nextID];
		}
		
 
		solutionValue += DistMatrix[route[j].CustomerNodeStationID];
		return solutionValue;
	} 

	//���ڷ���ʱ�̱����������
	//ͨ����վʱ�̱��Լ������ܵ���������Ƶ�εļ�ֵ

	struct waitVec {
		int demand;
		int waitTime;
	};

	__host__  float  userWaitFare(int userWaitTime,int userAboardTime) {

		if (userAboardTime <= 900) {
			float time = userWaitTime - 150;
			if (time < 0)
				time = 0;

			time = time / 120*1;

			if (time > 1.5)
				time = 1.5;

			return  time;
		}
		else if (userAboardTime > 900 && userAboardTime <= 1800) {

			float time = userWaitTime - 150;
			if (time < 0)
				time = 0;

			time = time / 60*1;

			if (time > 2.5)
				time = 2.5;

			return  time;
		}
		else if (userAboardTime > 1800 && userAboardTime <= 3600) {

			float time = userWaitTime - 150;
			if (time < 0)
				time = 0;

			time = time / 60 *1.5;
			
			if (time > 5)
				time = 5;


			return  time;
		}
	}


	__host__  float  freqEvaluate(std::deque<PDPTW::stationNode> pipeflow,std::vector<PDPTW::busNode> arriveTimeTable,PDPTW::disInfo dinfo) {
		
		//������վʱ�̱�

 
		float  totalcost = 0;

		for (int i = 0; i < arriveTimeTable.size(); i++) {
			
			//��ǰʱ�̱������վ�Ĺ�����
			PDPTW::busNode currentNode = arriveTimeTable[i];
			
			while (pipeflow.size() > 0) {

				PDPTW::stationNode snode = pipeflow[0];
				//�жϵ�ǰ�����Ƿ��ܽӿ�
				//�ж��Ƿ�����
				if (currentNode.currentDemand >= currentNode.busDemand)
					  break;


				 
				//���û�г����ж�վ̨�Ƿ����㹻�˿��ܹ��ϳ�
				if (snode.timeid <= currentNode.arrivetime) {

					 
					int newDemand = currentNode.currentDemand + snode.waitDemand;

					
					//�������ֻ��һ���ֿ���
					if (newDemand >= currentNode.busDemand) {
						
						int difDemand = currentNode.busDemand - currentNode.currentDemand;
						currentNode.currentDemand = currentNode.busDemand;

						//�ϳ�������������� - ��ǰ��������
						int newWaitTime = currentNode.arrivetime - snode.timeid;
						pipeflow[0].waitDemand = pipeflow[0].waitDemand - difDemand;
					 

						//�ж�վ�������Ƿ�Ϊ0�����Ϊ0��ɾ����ǰ�ڵ�
						if (pipeflow[0].waitDemand <= 0) {
							 
							pipeflow.pop_front();
						}

						float fare=userWaitFare(newWaitTime, currentNode.arrivetime);
						totalcost = totalcost + fare*difDemand;
					}
					//��������������ϵ�ǰվ��ȴ���ȫ������
					else {
						
						currentNode.currentDemand = currentNode.currentDemand + pipeflow[0].waitDemand;
						int difDemand = pipeflow[0].waitDemand;
						int newWaitTime = currentNode.arrivetime - snode.timeid;
						
						pipeflow[0].waitDemand = 0;
						pipeflow.pop_front();
					
						
						float fare = userWaitFare(newWaitTime, currentNode.arrivetime);
						totalcost = totalcost + fare*difDemand;
					}
				 
				}

				else {
					break;
				}
			}//end while
			//�жϵ�ǰ�����Ƿ�����ʽ���һ��
			
			//������Լ��
			//std::cout << currentNode.currentDemand << std::endl;

			if (currentNode.currentDemand >= 0.8*currentNode.busDemand) {
				totalcost += 0;
			}
			else {
				totalcost += 2.5 * (0.8*currentNode.busDemand - currentNode.currentDemand);
			}

			
			if (currentNode.isLast) {
				float travelDis = (currentNode.TravelDistance + dinfo.metroToDestDistance) / 1000.0;
				totalcost = totalcost+travelDis*2.296 + 83;				 
			}
		}

		for (int i = 0; i < pipeflow.size(); i++) {
			totalcost = totalcost + pipeflow[i].waitDemand * 5;
		}

	
		return totalcost;
	}




	__host__  float  _freqEvaluate(std::deque<PDPTW::stationNode> pipeflow, std::vector<PDPTW::busNode> arriveTimeTable, PDPTW::disInfo dinfo) {

		//������վʱ�̱�


		float  totalcost = 0;

		for (int i = 0; i < arriveTimeTable.size(); i++) {

			//��ǰʱ�̱������վ�Ĺ�����
			PDPTW::busNode currentNode = arriveTimeTable[i];

			while (pipeflow.size() > 0) {

				PDPTW::stationNode snode = pipeflow[0];
				//�жϵ�ǰ�����Ƿ��ܽӿ�
				//�ж��Ƿ�����
				if (currentNode.currentDemand >= currentNode.busDemand)
					break;



				//���û�г����ж�վ̨�Ƿ����㹻�˿��ܹ��ϳ�
				if (snode.timeid <= currentNode.arrivetime) {


					int newDemand = currentNode.currentDemand + snode.waitDemand;


					//�������ֻ��һ���ֿ���
					if (newDemand >= currentNode.busDemand) {

						int difDemand = currentNode.busDemand - currentNode.currentDemand;
						currentNode.currentDemand = currentNode.busDemand;

						//�ϳ�������������� - ��ǰ��������
						int newWaitTime = currentNode.arrivetime - snode.timeid;
						pipeflow[0].waitDemand = pipeflow[0].waitDemand - difDemand;


						//�ж�վ�������Ƿ�Ϊ0�����Ϊ0��ɾ����ǰ�ڵ�
						if (pipeflow[0].waitDemand <= 0) {

							pipeflow.pop_front();
						}

						float fare = userWaitFare(newWaitTime, currentNode.arrivetime);
						totalcost = totalcost + fare*difDemand;
					}
					//��������������ϵ�ǰվ��ȴ���ȫ������
					else {

						currentNode.currentDemand = currentNode.currentDemand + pipeflow[0].waitDemand;
						int difDemand = pipeflow[0].waitDemand;
						int newWaitTime = currentNode.arrivetime - snode.timeid;

						pipeflow[0].waitDemand = 0;
						pipeflow.pop_front();


						float fare = userWaitFare(newWaitTime, currentNode.arrivetime);
						totalcost = totalcost + fare*difDemand;
					}

				}

				else {
					break;
				}
			}//end while
			 //�жϵ�ǰ�����Ƿ�����ʽ���һ��

			 //������Լ��
			 //std::cout << currentNode.currentDemand << std::endl;

			if (currentNode.currentDemand >= 0.8*currentNode.busDemand) {
				totalcost += 0;
			}
			else {
				totalcost += 2.5 * (0.8*currentNode.busDemand - currentNode.currentDemand);
			}


			if (currentNode.isLast) {
				float travelDis = (currentNode.TravelDistance + dinfo.metroToDestDistance) / 1000.0;
				totalcost = totalcost + travelDis*2.296 + 83;
			}
		}

		for (int i = 0; i < pipeflow.size(); i++) {
			totalcost = totalcost + pipeflow[i].waitDemand * 5;
		}


		return totalcost;
	}




}