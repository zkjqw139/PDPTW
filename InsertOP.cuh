#pragma  once
#include "coeff.cuh"
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <time.h>
#include <deque> 
#include <algorithm>

//ALNS��ܵĲ������Ӽ���
//ʹ��CPUʵ��

namespace PDPTW {

	//��Ԫ�صı�ʾ��ʽ
	struct insertheapNode {
		int i;
		int j;
		PDPTW::CustomerNode node;


		insertheapNode(int i, int j, PDPTW::CustomerNode node) {
			this->i = i;
			this->j = j;
			this->node.CustomerNodeStationID = node.CustomerNodeStationID;
			this->node.NodeArriveTime        = node.NodeArriveTime;
			this->node.NodeDemand            = node.NodeDemand;
			this->node.NodeTimeWindowLeft    = node.NodeTimeWindowLeft;
			this->node.NodeTimeWindowRight   = node.NodeTimeWindowRight;
		}
	};//�ѽڵ�


	//function to insert one node in the Road set 
	__host__  void  InsertNodeToRoute(PDPTW::CustomerNode* Route, insertheapNode node, int *routeCount, int*routeCapcity) {

		if (node.i == -1 && node.j == -1) {
			printf("is return \n");
			printf("node station id is: %d ,node demand is : %d \n", node.node.CustomerNodeStationID,node.node.NodeDemand);
			return;
		}

		if (node.node.CustomerNodeStationID == 0) {
			return;
		}

		int  Index = node.j;
		int  i     = node.i;
		
 

		//printf("insert position %d %d", node.i, node.j);
		
		for (int j = routeCount[i]; j >Index; j--) {

					Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID = Route[i*PDPTW::maxUserSize + j-1].CustomerNodeStationID;
					Route[i*PDPTW::maxUserSize + j].NodeArriveTime        = Route[i*PDPTW::maxUserSize + j-1].NodeArriveTime;
					Route[i*PDPTW::maxUserSize + j].NodeDemand            = Route[i*PDPTW::maxUserSize + j-1].NodeDemand;
					Route[i*PDPTW::maxUserSize + j].NodeTimeWindowLeft    = Route[i*PDPTW::maxUserSize + j-1].NodeTimeWindowLeft;
					Route[i*PDPTW::maxUserSize + j].NodeTimeWindowRight   = Route[i*PDPTW::maxUserSize + j-1].NodeTimeWindowRight;

		}

		Route[i*PDPTW::maxUserSize + Index].CustomerNodeStationID = node.node.CustomerNodeStationID;
		Route[i*PDPTW::maxUserSize + Index].NodeArriveTime        = node.node.NodeArriveTime;
		Route[i*PDPTW::maxUserSize + Index].NodeDemand            = node.node.NodeDemand;
		Route[i*PDPTW::maxUserSize + Index].NodeTimeWindowLeft    = node.node.NodeTimeWindowLeft;
		Route[i*PDPTW::maxUserSize + Index].NodeTimeWindowRight   = node.node.NodeTimeWindowRight;



		routeCount[i] = routeCount[i] + 1;
		routeCapcity[i] = routeCapcity[i] + node.node.NodeDemand;
		//printf(" insert position is %d %d\n\n",i, Index);
	}


	
	//���㵱ǰ�ڵ������·��ÿһ��λ�õĴ���
	__host__  void getBestInsertPosition(PDPTW::CustomerNode* Route, PDPTW::CustomerNode node, int* routeCount, int* routeCapcity, int & routeNum, float* DistMatrix, size_t * UserSize) {

		//�û�����
		size_t len = *(UserSize);

		int insertId = node.CustomerNodeStationID;
 
		insertheapNode insertnode(-1, -1, node);

		//����ÿһ���켣
		float mincost = 999999;
		for (int i = 0; i <= routeNum; i++) {

			//�����켣ÿһ���ڵ�

			for (int j = 0; j < routeCount[i]+1; j++) {

				

				float cost = 0;

				int   currentID = Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID;
				int   preID = 0;

				if (j > 0) {
					preID = Route[i*PDPTW::maxUserSize + j - 1].CustomerNodeStationID;
				}
 

				if (j == routeCount[i]) {
					currentID = 0;
				}

				//����ÿһ���ڵ�Ŀ���

				//printf("Dist %d %d is : cost %f %f %f \n",i,j, DistMatrix[currentID*len + preID], DistMatrix[currentID*len + nextID], DistMatrix[preID*len + nextID]);



				cost = DistMatrix[insertId*len + preID]     + \
					   DistMatrix[insertId*len + currentID] - \
					   DistMatrix[preID*len + currentID];
 
				
				if (cost <= mincost && routeCapcity[i]+node.NodeDemand<=80) {

					insertnode.i = i;
					insertnode.j = j;
					mincost = cost;
				}
			}
		}

		//insert the insertheapnode
		if (insertnode.i >= 0 && insertnode.j >= 0) {
			InsertNodeToRoute(Route, insertnode, routeCount, routeCapcity);
		}
		else {
			insertnode.i = routeNum+1;
			insertnode.j = 0;
			InsertNodeToRoute(Route, insertnode, routeCount, routeCapcity);
		}

		 
	}

	//�������
	__host__  void getRandomInsertPosition(PDPTW::CustomerNode* Route, PDPTW::CustomerNode node, int* routeCount, int* routeCapcity, int & routeNum, float* DistMatrix, size_t * UserSize) {

		//�û�����
		size_t len = *(UserSize);

		int insertId = node.CustomerNodeStationID;

		insertheapNode insertnode(-1, -1, node);
		
		srand(static_cast<unsigned>(time(0)));
		int i = rand() % (routeNum+1);

		while (routeCapcity[i] + node.NodeDemand > 80) {
			i = rand() % (routeNum+1);
		}

		int j = rand() % (routeCount[i]+1);

		insertnode.i = i;
		insertnode.j = j;
		 
		InsertNodeToRoute(Route, insertnode, routeCount, routeCapcity);

	}




	//̰�ģ�̰������ÿ��ֻ���뵱ǰ��ѵĲ���λ��
	__host__ void greedyInsert(PDPTW::CustomerNode * Route, std::vector<PDPTW::CustomerNode> requestPool, int & routeNum, int * routeCount, int * routeCapacity, float* DistMatrix, size_t * UserSize) {

		std::random_shuffle(requestPool.begin(), requestPool.end());
		//����ÿһ��request �������������λ�����Ĳ���cost��ѡ��cost��С�����Ҳ��ᳬ��·���������Ƶ�·�߲���
		for (int i = 0; i < requestPool.size(); i++) {
			//printf(" %d request need to insert  and this node demand is %d  \n", requestPool[i].CustomerNodeStationID,requestPool[i].NodeDemand);
			getBestInsertPosition(Route, requestPool[i], routeCount, routeCapacity, routeNum, DistMatrix, UserSize);
		}
	}


	//�������
	__host__ void randomInsert(PDPTW::CustomerNode * Route, std::vector<PDPTW::CustomerNode> requestPool, int & routeNum, int * routeCount, int * routeCapacity, float* DistMatrix, size_t * UserSize) {

		std::random_shuffle(requestPool.begin(), requestPool.end());
		//����ÿһ��request �������������λ�����Ĳ���cost��ѡ��cost��С�����Ҳ��ᳬ��·���������Ƶ�·�߲���
		for (int i = 0; i < requestPool.size(); i++) {
			//printf(" %d request need to insert  and this node demand is %d  \n", requestPool[i].CustomerNodeStationID, requestPool[i].NodeDemand);
			getRandomInsertPosition(Route, requestPool[i], routeCount, routeCapacity, routeNum, DistMatrix, UserSize);
		}
	}









 

}


