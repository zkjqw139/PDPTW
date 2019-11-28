#pragma  once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cublas.h>

namespace PDPTW {

	struct UserGroup {
		
		//�û�����
		int groupID;                //�û�ID
		int UserUpStationID;        //�û��ϳ�վ��ID
		int UserDownStationID;      //�û��³�վ��ID
		float UserUpStationLon;     //�û��ϳ�վ�㾭��
		float UserUpStationLat;     //�û��ϳ�վ��ά��

		int expectArriveTime;
		//int UserServiceTime;       //�û�����Ҫ�ķ���ʱ��
		int userCount;               //��ʾͬһվ����û�������Ŀ��userʵ�ʱ�ʾ����һȺ����ͬ������û�

		//�û���ʼ�� 
		UserGroup(int groupID, int UserUpStationID, int UserDownStationID, int UserDemand) {

			this->groupID = groupID;
			this->UserUpStationID         = UserUpStationID;
			this->UserDownStationID       = UserDownStationID;
			this->userCount = UserDemand;

		}

	};

}
