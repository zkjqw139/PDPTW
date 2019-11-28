#pragma  once
#include "coeff.cuh"
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <time.h>

namespace PDPTW {

	__host__ int  findArgMin(int index,size_t* UserSize, float* DistMatrix,std::vector<PDPTW::UserGroup> requestPool) {

		float minValue    = 10000;
		int   targetIndex = 0;

		for (int i = 0; i < requestPool.size(); i++) {

			int id = requestPool[i].groupID - 1;
			if (index == id) {
				continue;
			}


			float dist = DistMatrix[index*(*UserSize) + id];

			if (minValue>dist) {
				minValue = dist;
				targetIndex = i;
			}
		}

		return targetIndex;
	}



	__host__  int BaseInit(PDPTW::UserGroup *users, size_t* UserSize, PDPTW::CustomerNode *Route,int*RouteCapcity,int* RouteCount,float* DistMatrix) {
		
		//Users         ������ӣ�������Ҫ��վ���û�
		//UserSize      �û����������
		//Route         ��ʼ׼�����ɵ���·��ʾ��ʽΪ�����·��Ŀ*����û���Ŀ�ľ���
		//RouteCount    ͳ��������·�Ľڵ���Ŀ�����������Ѱ
		//RouteCapacity ͳ�Ƶ�ǰ��·������  
		//DistMatrix    һ�����������Է����Ѱ�ҳ��ڵ�֮��ľ���

		//��ʼ��������
		const int VehicleCapcity = 80;
		int   k = 0; //��ǰ���ڳ�ʼ���ĳ������

		//step1
		//��ʼ���û��������
		std::vector<PDPTW::UserGroup> requestPool;
		for (int i = 0; i < *UserSize; i++) {
			if (users[i].groupID == 1)
				continue;
			requestPool.push_back(users[i]);
		}

		bool *UserIsUsed = (bool*)malloc((*UserSize) * sizeof(bool));
		for (int i = 0; i < (*UserSize); i++) {
			UserIsUsed[i] = false;
		}
        
		//���Զ�ÿһ���û�ִ�в���
		printf("request num is : %d \n", requestPool.size());
		while (requestPool.size() > 0) {

			//��ǰ����û��ͣ��վ�㣬����һ�����վ����뵱ǰ��·
			if (Route[k*PDPTW::maxUserSize].CustomerNodeStationID == 0) {
			   
				srand((unsigned)time(NULL));
				int Index = rand() % (requestPool.size());
				int randIndex = requestPool[Index].groupID-1;
				
				int nDemand = users[randIndex].userCount;
				if(nDemand>64){
					requestPool.erase(requestPool.begin() + Index);
					*UserSize =*UserSize -1;
					continue;
				}	

				Route[k*PDPTW::maxUserSize].CustomerNodeStationID = randIndex;
				Route[k*PDPTW::maxUserSize].UserID = randIndex;
				Route[k*PDPTW::maxUserSize].NodeDemand = users[randIndex].userCount;
				RouteCapcity[k] += users[randIndex].userCount;
				RouteCount[k] += 1;
				requestPool.erase(requestPool.begin() + Index);
				UserIsUsed[k] = true;

			}
			//��ǰ��վ�Ѿ���ͣ��վ�㣬Ѱ�ҵ�ǰվ������վ�����
			else {

				int targetIndex = Route[k*PDPTW::maxUserSize].CustomerNodeStationID;
				int UserIndex   = findArgMin(targetIndex, UserSize, DistMatrix, requestPool);
				int UserID      = requestPool[UserIndex].groupID - 1;
				int tempCapcity = users[UserID].userCount + RouteCapcity[k];

				//������ػ������㵱ǰ��������û�����ѡ����һ��·��
				if (tempCapcity >= VehicleCapcity || RouteCount[k]>PDPTW::maxUserSize) {
					k = k + 1;
					continue;
				}

				//���û�г����򽫽ڵ���뵱ǰ·��
				else {
					
					
					int nDemand = users[UserID].userCount;
					if(nDemand>64){
						requestPool.erase(requestPool.begin() + UserIndex);
						*UserSize =*UserSize -1;
						continue;
					}	


					Route[k*PDPTW::maxUserSize+ RouteCount[k]].CustomerNodeStationID = UserID;
					Route[k*PDPTW::maxUserSize+ RouteCount[k]].UserID = UserID;
					Route[k*PDPTW::maxUserSize+ RouteCount[k]].NodeDemand = users[UserID].userCount;
					RouteCapcity[k] += users[UserID].userCount;
					RouteCount[k] += 1;
					requestPool.erase(requestPool.begin() + UserIndex);
					UserIsUsed[k] = true;
				}
			}

		}

		//������Ч��·����Ŀ
		return k;



	}


}