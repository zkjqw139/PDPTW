#pragma  once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cublas.h>

namespace PDPTW {

	struct UserGroup {
		
		//用户属性
		int groupID;                //用户ID
		int UserUpStationID;        //用户上车站点ID
		int UserDownStationID;      //用户下车站点ID
		float UserUpStationLon;     //用户上车站点经度
		float UserUpStationLat;     //用户上车站点维度

		int expectArriveTime;
		//int UserServiceTime;       //用户所需要的服务时间
		int userCount;               //表示同一站点的用户需求数目，user实际表示的是一群有相同需求的用户

		//用户初始化 
		UserGroup(int groupID, int UserUpStationID, int UserDownStationID, int UserDemand) {

			this->groupID = groupID;
			this->UserUpStationID         = UserUpStationID;
			this->UserDownStationID       = UserDownStationID;
			this->userCount = UserDemand;

		}

	};

}
