#pragma  once
#include "coeff.cuh"
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <time.h>
#include <deque> 
#include <algorithm>
#include "evaluate.cuh"
//ALNS���ܱ�׼�����Ӽ���
//����Ϊ������һ���������Ƿ������
//ʹ��CPUʵ��

namespace PDPTW {

	int checkRouteCount(PDPTW::CustomerNode* host_Route, int* routeCount, int* routeCapcity, int routeNum) {

		int rCount = 0;
		for (int i = 0; i <= routeNum; i++) {
			rCount += routeCount[i];
		}

		//printf("routeCount is %d\n", rCount);

		return rCount;


	}

	__host__ void RouteCopy(PDPTW::CustomerNode* currentRoute, PDPTW::CustomerNode* bestRoute, size_t* UserSize, int routeNum, int *routeCount, int *routeCapacity, int* bestRouteCount, int* bestRouteCapacity) {

		for (int i = 0; i <= routeNum; i++) {
			for (int j = 0; j < routeCount[i]; j++) {
				bestRoute[i*PDPTW::maxUserSize + j].CustomerNodeStationID = currentRoute[i*PDPTW::maxUserSize + j].CustomerNodeStationID;
				bestRoute[i*PDPTW::maxUserSize + j].UserID = currentRoute[i*PDPTW::maxUserSize + j].UserID;
				bestRoute[i*PDPTW::maxUserSize + j].UserAction = currentRoute[i*PDPTW::maxUserSize + j].UserAction;
				bestRoute[i*PDPTW::maxUserSize + j].NodeDemand = currentRoute[i*PDPTW::maxUserSize + j].NodeDemand;
				bestRoute[i*PDPTW::maxUserSize + j].NodeTimeWindowLeft = currentRoute[i*PDPTW::maxUserSize + j].NodeTimeWindowLeft;
				bestRoute[i*PDPTW::maxUserSize + j].NodeTimeWindowRight = currentRoute[i*PDPTW::maxUserSize + j].NodeTimeWindowRight;
			}
		}

		for (int i = 0; i < (*UserSize); i++) {
			bestRouteCount[i] = routeCount[i];
			bestRouteCapacity[i] = routeCapacity[i];
		}


	}


	//̰�����ܵ�ǰ��ȹ�ȥ�����ۺ������ָ��õ�ʱ���ѡ����ܵ�ǰ�����ɵĽ�
	__host__ void greedyAccept(PDPTW::CustomerNode* currentRoute, PDPTW::CustomerNode* bestRoute, size_t* size, float* host_DistMatrix, int routeNum, int* routeCount, int* routeCapacity, int bestRoutNum, int* bestRouteCount, int* bestRouteCapacity) {

		float currentSolutionValue = PDPTW::BaseEvaluate(currentRoute, size, host_DistMatrix, routeNum, routeCount);
		float bestSolutionValue = PDPTW::BaseEvaluate(bestRoute, size, host_DistMatrix, bestRoutNum, bestRouteCount);

		printf("result is %f %f \n\n", currentSolutionValue, bestSolutionValue);
		
		if (currentSolutionValue < bestSolutionValue) {
			printf("find one best solution\n");
			RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
		}
	}


	//����ģ���˻�ѡ���Ƿ���ܽ�
	__host__ void simulatedAnnelAccept(PDPTW::CustomerNode* currentRoute, PDPTW::CustomerNode* bestRoute, 
									   size_t* size, float* host_DistMatrix, 
		                               int routeNum, int* routeCount, int* routeCapacity,
		                               int bestRoutNum, int* bestRouteCount, int* bestRouteCapacity,std::vector<float> & RemoveMethodWeight,int & removeMethodType , int bestVal) {

		//��ʼ����ʼ�¶�
		static float T = 100;

		//��ʼ��˥��ϵ��
		static float a = 0.999999;

		int rcount=checkRouteCount(currentRoute, routeCount, routeCapacity, routeNum);


		if (rcount < *size-1){
			std::cout << *size << std::endl;
			printf("rcount is %d less than 35\n",rcount);
			return;
		} 

		//��ǰ�������ֵ
		float currentSolutionValue = PDPTW::BaseEvaluate(currentRoute, size, host_DistMatrix, routeNum, routeCount);

		//��ѽ������ֵ
		float bestSolutionValue    = PDPTW::BaseEvaluate(bestRoute, size, host_DistMatrix, bestRoutNum, bestRouteCount);

		//��ʾ��
		//printf("result is %f %f \n\n", currentSolutionValue, bestSolutionValue);
		

		//������Ĳ�ֵ
		float diffSolutionValue = currentSolutionValue - bestSolutionValue;

		//���ܸ���
		float acceptProb = exp(-abs(diffSolutionValue) / T);

		//printf("\n accept prob is : %f \n", acceptProb);

		//���ɸ���
		srand((UINT)GetCurrentTime());
		float randNum = (rand() % 100)/(float)(101)+0.1;
		
		//printf("generator prob is: %f \n", randNum);

		//����������ɵĸ���С�ڽ��ܸ��������
        //�����ǰ�����ۺ��ڵ�ǰ����һ������
		if (currentSolutionValue < bestVal) {
			RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
			RemoveMethodWeight[removeMethodType] += 20;
		}
		else if (currentSolutionValue<bestSolutionValue) {
			RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
			RemoveMethodWeight[removeMethodType] += 10;
		}
		//���������ǰ�����һ�����ʱȵ�ǰ�������������ڸ��ʽ���
		else {
			if (randNum < acceptProb) {
				RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
				RemoveMethodWeight[removeMethodType] += 5;
			}	
			//�����¶�
			if (T > 0.1) {
				T = a*T;
			}
		}

	
	}


	//����ģ���˻�ѡ���Ƿ���ܽ�
	__host__ void originSimulatedAnnelAccept(PDPTW::CustomerNode* currentRoute, PDPTW::CustomerNode* bestRoute,
		size_t* size, float* host_DistMatrix,
		int routeNum, int* routeCount, int* routeCapacity,
		int bestRoutNum, int* bestRouteCount, int* bestRouteCapacity) {

		//��ʼ����ʼ�¶�
		static float T = 100;

		//��ʼ��˥��ϵ��
		static float a = 0.999999;

		int rcount = checkRouteCount(currentRoute, routeCount, routeCapacity, routeNum);


		if (rcount < *size - 1) {
			//std::cout << *size << std::endl;
			//printf("rcount is %d less than 35\n", rcount);
			return;
		}

		//��ǰ�������ֵ
		float currentSolutionValue = PDPTW::BaseEvaluate(currentRoute, size, host_DistMatrix, routeNum, routeCount);

		//��ѽ������ֵ
		float bestSolutionValue = PDPTW::BaseEvaluate(bestRoute, size, host_DistMatrix, bestRoutNum, bestRouteCount);

		//��ʾ��
		//printf("result is %f %f \n\n", currentSolutionValue, bestSolutionValue);


		//������Ĳ�ֵ
		float diffSolutionValue = currentSolutionValue - bestSolutionValue;

		//���ܸ���
		float acceptProb = exp(-abs(diffSolutionValue) / T);

		//printf("\n accept prob is : %f \n", acceptProb);

		//���ɸ���
		srand((UINT)GetCurrentTime());
		float randNum = (rand() % 100) / (float)(101) + 0.1;

		//printf("generator prob is: %f \n", randNum);

		//����������ɵĸ���С�ڽ��ܸ��������
		//�����ǰ�����ۺ��ڵ�ǰ����һ������
		if (currentSolutionValue < bestSolutionValue) {
			RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);

		}
		//���������ǰ�����һ�����ʱȵ�ǰ�������������ڸ��ʽ���
		else {
			if (randNum < acceptProb) {
				RouteCopy(currentRoute, bestRoute, size, routeNum, routeCount, routeCapacity, bestRouteCount, bestRouteCapacity);
			}
			//�����¶�
			if (T > 0.1) {
				T = a*T;
			}
		}


	}



}
 