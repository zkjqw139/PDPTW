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
		
		//Users         需求池子，所有需要上站的用户
		//UserSize      用户需求的数量
		//Route         开始准备生成的线路表示型式为最大线路数目*最大用户数目的矩阵
		//RouteCount    统计所有线路的节点数目，方便快速搜寻
		//RouteCapacity 统计当前线路的容量  
		//DistMatrix    一个距离矩阵可以方便的寻找出节点之间的距离

		//初始化车容量
		const int VehicleCapcity = 80;
		int   k = 0; //当前正在初始化的车辆编号

		//step1
		//初始化用户请求池子
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
        
		//尝试对每一个用户执行插入
		printf("request num is : %d \n", requestPool.size());
		while (requestPool.size() > 0) {

			//当前车还没有停靠站点，生成一个随机站点插入当前线路
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
			//当前车站已经有停靠站点，寻找当前站点的最近站点插入
			else {

				int targetIndex = Route[k*PDPTW::maxUserSize].CustomerNodeStationID;
				int UserIndex   = findArgMin(targetIndex, UserSize, DistMatrix, requestPool);
				int UserID      = requestPool[UserIndex].groupID - 1;
				int tempCapcity = users[UserID].userCount + RouteCapcity[k];

				//如果超载或者满足当前车辆最大用户数则选择新一条路线
				if (tempCapcity >= VehicleCapcity || RouteCount[k]>PDPTW::maxUserSize) {
					k = k + 1;
					continue;
				}

				//如果没有超载则将节点插入当前路径
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

		//返回有效线路的数目
		return k;



	}


}