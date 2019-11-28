#pragma  once
#include "coeff.cuh"
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <time.h>
#include <deque> 
#include <algorithm>

//ALNS ��ܵ�ɾ�����Ӽ���
//ʹ��CPUʵ��

namespace PDPTW {

	//���ɾ��
	//���������ѡ��q�������Ӧ·��ɾ���������������Ĺ��
	__host__  std::vector<PDPTW::CustomerNode>  randomRemove(PDPTW::CustomerNode* Route,int* routeCount,int* routeCapcity,int routeNum) {
		//��������������ѡ����Ҫɾ����վ��
		std::vector<PDPTW::CustomerNode> RequestPool;

		for (int _i = 0; _i < 1; _i++) {
			for (int i = 0; i <= routeNum; i++) {

				//
				srand(static_cast<unsigned>(time(0)));

				if (routeCount[i] == 0) {
					continue;
				}

				int Index = rand() % (routeCount[i]);


				//ɾ�������ѡ����û������Ұ�����û�������������
				if (Index <= routeCount[i] - 1) {

					RequestPool.push_back(Route[i*PDPTW::maxUserSize + Index]);
					//printf("%d %d ,%d nodeDemand %drouteCount \n", i, Index, Route[i*PDPTW::maxUserSize + Index].NodeDemand,routeCount[i]);

					routeCapcity[i] = routeCapcity[i] - Route[i*PDPTW::maxUserSize + Index].NodeDemand;
					//���º����û�
					for (int j = Index + 1; j <= routeCount[i]; j++) {

						Route[i*PDPTW::maxUserSize + j - 1].CustomerNodeStationID = Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID;
						Route[i*PDPTW::maxUserSize + j - 1].NodeArriveTime = Route[i*PDPTW::maxUserSize + j].NodeArriveTime;
						Route[i*PDPTW::maxUserSize + j - 1].NodeDemand = Route[i*PDPTW::maxUserSize + j].NodeDemand;
						Route[i*PDPTW::maxUserSize + j - 1].NodeTimeWindowLeft = Route[i*PDPTW::maxUserSize + j].NodeTimeWindowLeft;
						Route[i*PDPTW::maxUserSize + j - 1].NodeTimeWindowRight = Route[i*PDPTW::maxUserSize + j].NodeTimeWindowRight;

					}
					routeCount[i] = routeCount[i] - 1;

				}

			}
		}

		return RequestPool;
	}//End Random Remove

 

	//���ɾ��
	//Ŀ����ѡ����ֵ�õ�request���ӽ����Ƴ������Ҳ��뵽�����ط�����һ�����õĽ�
	//̰���㷨


	//����������·��ÿһ���ڵ�Ĵ���
	__host__  float* getCostMatrix(PDPTW::CustomerNode* Route, int* routeCount, int* routeCapcity, int routeNum, float* DistMatrix, size_t * UserSize) {
		
		//�û�����
		size_t len = *(UserSize);

		//��ʼ������
		float * costMatrix;
		costMatrix =(float*)malloc(PDPTW::maxRouteCounts*PDPTW::maxUserSize * sizeof(float));
		for (int i = 0; i <PDPTW::maxRouteCounts; i++) {
			for (int j = 0; j < PDPTW::maxUserSize; j++) {
				costMatrix[i*PDPTW::maxUserSize + j] = 0;
			}
		}


 		//����ÿһ���켣
		for (int i = 0; i <= routeNum; i++) {

			//�����켣ÿһ���ڵ�

			for (int j = 0; j < routeCount[i]; j++) {

				float cost = 0;

				int   currentID = Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID;
				int   preID  = 0;
				int   nextID = 0;

				if (j > 0) {
					  preID = Route[i*PDPTW::maxUserSize + j-1].CustomerNodeStationID;
				}

				if (j < routeCount[i] - 1) {
					nextID = Route[i*PDPTW::maxUserSize + j + 1].CustomerNodeStationID;
				}


				//����ÿһ���ڵ�Ŀ���
				
				//printf("Dist %d %d is : cost %f %f %f \n",i,j, DistMatrix[currentID*len + preID], DistMatrix[currentID*len + nextID], DistMatrix[preID*len + nextID]);

				cost = DistMatrix[currentID*len + preID] + \
					   DistMatrix[currentID*len + nextID] - \
					   DistMatrix[preID*len + nextID];

				costMatrix[i*PDPTW::maxUserSize + j] = cost;

			}
		}



		return costMatrix;
	}
	//reload ������ʾ����ÿһ���ڵ�Ĵ���
	//��ʾcost matrix �ļ�����
	__host__ void showCostMatrix(float* costMatrix, int* routeCount, int routeNum) {
		
		for (int i = 0; i <=routeNum; i++) {
			printf("\n");
			for (int j = 0; j < routeCount[i]; j++) {
				printf("%f ", costMatrix[i*PDPTW::maxUserSize + j]);
			}
		}

		
	}//end show CostMatirx

	//Ѱ��ǰk����СԪ�ص��㷨
	//��һ���������ݽṹ

	//��Ԫ�صı�ʾ��ʽ
	struct heapNode {
		int i;
		int j;
		float cost;

		heapNode& operator=(heapNode & h) {
			i = h.i;
			j = h.j;
			cost = h.cost;
			return *this;
		}


		heapNode(int i, int j, float cost) {
			this->i = i;
			this->j = j;
			this->cost = cost;
		}
	};//�ѽڵ�
	
	//�ѵı�ʾ��ʽ
	struct heap {
		

		int k;
		heapNode *heapArray;
	    
		//�ѳ�ʼ��
		heap(int Num) {
			k = Num;
			heapArray = (heapNode*)malloc(k * sizeof(heapNode));
			for (int i = 0; i < k; i++) {
				heapArray[i].i = 0;
				heapArray[i].j = 0;
				heapArray[i].cost = 0;

			}
		}

		//��һ���ѽڵ�����
		//����ڵ�cost���ڶ���С�ڵ�cost��������
		void insertNode(heapNode h) {
			 
			heapNode smallNode = heapArray[k - 1];
		    
			if (h.cost > smallNode.cost) {

				heapArray[k - 1] = h;
				int  currInd = k - 1;

				while (currInd > 0) {
					if (heapArray[currInd].cost > heapArray[currInd - 1].cost) {
						heapNode t = heapArray[currInd - 1];
						heapArray[currInd - 1] = heapArray[currInd];
						heapArray[currInd] = t;
						currInd = currInd - 1;
					}
					else {
						break;
					}
			  }//End swap Node
			}//if cost large than smallest Node cost ,insert the node
		}
	};
    
	//function to delete one node in the Road set 
	__host__  void  removeNodeFromRoute(PDPTW::CustomerNode* Route, heapNode node, int *routeCount, int*routeCapcity) {
		
		if (routeCount[node.i] <= 0) {
			return;
		}

		int Index = node.j;
		int i = node.i;
		//printf("%d %d ,%d nodeDemand routeCount %d \n", i, Index, Route[i*PDPTW::maxUserSize + Index].NodeDemand,routeCount[i]);
		routeCapcity[i] = routeCapcity[i] - Route[node.i*PDPTW::maxUserSize + node.j].NodeDemand;
		

		for (int j = Index + 1; j <=routeCount[i]; j++) {

			Route[i*PDPTW::maxUserSize + j - 1].CustomerNodeStationID = Route[i*PDPTW::maxUserSize + j].CustomerNodeStationID;
			Route[i*PDPTW::maxUserSize + j - 1].NodeArriveTime = Route[i*PDPTW::maxUserSize + j].NodeArriveTime;
			Route[i*PDPTW::maxUserSize + j - 1].NodeDemand = Route[i*PDPTW::maxUserSize + j].NodeDemand;
			Route[i*PDPTW::maxUserSize + j - 1].NodeTimeWindowLeft = Route[i*PDPTW::maxUserSize + j].NodeTimeWindowLeft;
			Route[i*PDPTW::maxUserSize + j - 1].NodeTimeWindowRight = Route[i*PDPTW::maxUserSize + j].NodeTimeWindowRight;

		}
		routeCount[i] = routeCount[i] - 1;
		
		

	}


	__host__  std::vector<PDPTW::CustomerNode>  worstRemove(PDPTW::CustomerNode* Route, int* routeCount, int* routeCapcity, int routeNum,float* DistMatrix,size_t * UserSize) {

		std::vector<PDPTW::CustomerNode> RequestPool;
		int  qnum = routeNum;

		//������·��ÿһ��վ��Ĵ���
		float * costMatirx;
		costMatirx = getCostMatrix(Route, routeCount, routeCapcity, routeNum, DistMatrix, UserSize);
		
		//��ʼ���ѽڵ�
		heap maxCostHeap(qnum);

		//ѡ��qnum���������Ľڵ�
		for (int i = 0; i <= routeNum; i++) {
			for (int j = 0; j < routeCount[i]; j++) { 
				float cost        = costMatirx[i*PDPTW::maxUserSize+j];
				heapNode currNode(i, j, cost);
				maxCostHeap.insertNode(currNode);
			}
		}
		
		//����·����ɾ�����е�Ԫ��,���ҽ�Ҫɾ����Ԫ�ؼ��뵽�������
		for (int i = 0; i < qnum; i++) {
			heapNode tempNode = maxCostHeap.heapArray[i];

			bool isinPool=false;
			for (int j = 0; j < RequestPool.size(); j++) {
				
				if (Route[tempNode.i*PDPTW::maxUserSize + tempNode.j].CustomerNodeStationID == RequestPool[j].CustomerNodeStationID)
					isinPool = true;
			}

			if (isinPool) {
				continue;
			}


			RequestPool.push_back(Route[tempNode.i*PDPTW::maxUserSize + tempNode.j]);
			removeNodeFromRoute(Route,tempNode,routeCount, routeCapcity);
			int _i = maxCostHeap.heapArray[i].i;
			int _j = maxCostHeap.heapArray[i].j;

			for (int j = i + 1; j < qnum; j++) {

				int t_i = maxCostHeap.heapArray[j].i;
				int t_j = maxCostHeap.heapArray[j].j;

				if (t_i == _i && t_j > _j) {
					maxCostHeap.heapArray[j].j = maxCostHeap.heapArray[j].j - 1;
				}


			}
		}
		free(costMatirx);
		costMatirx = NULL;

		return RequestPool;

	}//End Worst Remove
    
	 //������ɾ��
	//���������Ծ���

	__host__  std::vector<PDPTW::CustomerNode>  relatedRemove(PDPTW::CustomerNode* Route, int* routeCount, int* routeCapcity, int routeNum, float* DistMatrix, size_t * UserSize) {

		//��cvrp �������ѡ��һ��վ��ѡ�����ɸ�������������ĵ�ɾ��
		int len = *(UserSize);
		std::vector<PDPTW::CustomerNode> RequestPool;
		int  qnum = routeNum/2;
		
		srand((unsigned)time(NULL));
		int _i = rand() % (routeNum+1);
		if (routeCount[_i] == 0) {
			return RequestPool;
		}
		int _j = rand() % routeCount[_i];

		int currentUserID = Route[PDPTW::maxUserSize*_i + _j].CustomerNodeStationID;

		//��ʼ���ѽڵ�
		heap maxCostHeap(qnum);

		//ѡ��qnum�����������ƵĽڵ�
		for (int i = 0; i <= routeNum; i++) {
			for (int j = 0; j < routeCount[i]; j++) {

				int targetUserID = Route[PDPTW::maxUserSize*i + j].CustomerNodeStationID;
				if (currentUserID == targetUserID) {
					continue;
				}
				float cost = 1/DistMatrix[currentUserID*len + targetUserID];
				heapNode currNode(i, j, cost);
				maxCostHeap.insertNode(currNode);
			}
		}

		//heapNode tempNode(_i, _j, 0.0);
		//RequestPool.push_back(Route[tempNode.i*PDPTW::maxUserSize + tempNode.j]);
		//removeNodeFromRoute(Route, tempNode, routeCount, routeCapcity);
		//����·����ɾ�����е�Ԫ��,���ҽ�Ҫɾ����Ԫ�ؼ��뵽�������
		for (int i = 0; i < qnum; i++) {
			
			heapNode tempNode = maxCostHeap.heapArray[i];
			RequestPool.push_back(Route[tempNode.i*PDPTW::maxUserSize + tempNode.j]);
			removeNodeFromRoute(Route, tempNode, routeCount, routeCapcity);
			
			int _i = maxCostHeap.heapArray[i].i;
			int _j = maxCostHeap.heapArray[i].j;

			for (int j = i + 1; j < qnum; j++) {

				int t_i = maxCostHeap.heapArray[j].i;
				int t_j = maxCostHeap.heapArray[j].j;

				if (t_i == _i && t_j > _j) {
					maxCostHeap.heapArray[j].j = maxCostHeap.heapArray[j].j - 1;
				}
			}

		}
		return RequestPool;

	}//������ɾ������


	//ȷ�������ɾ��

   


	//������ʷɾ��

}








 