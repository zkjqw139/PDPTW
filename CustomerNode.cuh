#pragma  once
#include "device_launch_parameters.h"
#include <cuda_runtime.h>
#include <curand.h>
#include <curand_kernel.h>
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cublas.h>




namespace PDPTW {
	
	const int maxTime = 99999999;

	struct  CustomerNode {

		//�û��ڵ����
		int  CustomerNodeStationID;   // �û��ڵ��վ��
		int  UserID;                  // ����ڵ���û�ID
		int  NodeDemand;              // ����ڵ���û���������
		bool UserAction;              // ����û����ϳ� UserAction is True ����  UserAction is False
		int  NodeArriveTime;          // ��ǰ�ڵ��û�����ʱ��
		int  NodeTimeWindowLeft;      // ��ǰ�ڵ�ʱ�䴰���
		int  NodeTimeWindowRight;     // ��ǰ�ڵ�ʱ�䴰�Ҳ�

		//�ڵ��ʼ��



		__host__ CustomerNode() {

			this->CustomerNodeStationID = 0;
			this->UserID = 0;
			this->NodeDemand = 0;
			this->UserAction = false;
			this->NodeArriveTime      = PDPTW::maxTime;
			this->NodeTimeWindowLeft  = PDPTW::maxTime;
			this->NodeTimeWindowRight = PDPTW::maxTime;
		}

		__host__ CustomerNode(int CustomeStationID,int UserID, int NodeDemand, bool UserAction, int NodeArriveTime, int NodeTimeWindowLeft, int NodeTimeWindowRight) {

			this->CustomerNodeStationID = CustomeStationID;
			this->UserID                = UserID;
			this->NodeDemand            = NodeDemand;
			this->UserAction            = UserAction;
			this->NodeArriveTime        = NodeArriveTime;
			this->NodeTimeWindowLeft    = NodeTimeWindowLeft;
			this->NodeTimeWindowRight   = NodeTimeWindowRight;
		}

		__host__ CustomerNode(int CustomeStationID, int UserID, int NodeDemand, bool UserAction, int NodeTimeWindowLeft, int NodeTimeWindowRight) {

			this->CustomerNodeStationID = CustomeStationID;
			this->UserID                = UserID;
			this->NodeDemand            = NodeDemand;
			this->UserAction            = UserAction;
			this->NodeTimeWindowLeft    = NodeTimeWindowLeft;
			this->NodeTimeWindowRight   = NodeTimeWindowRight;
			this->NodeArriveTime        =(this->NodeTimeWindowLeft+this->NodeTimeWindowRight)/2;
		}

		__host__ CustomerNode(int CustomeStationID, int UserID, int NodeDemand, bool UserAction, int NodeArriveTime) {

			this->CustomerNodeStationID = CustomeStationID;
			this->UserID                = UserID;
			this->NodeDemand            = NodeDemand;
			this->UserAction            = UserAction;
			this->NodeArriveTime        = NodeArriveTime;
			this->NodeTimeWindowLeft    = this->NodeArriveTime-60;
			this->NodeTimeWindowRight   = this->NodeArriveTime+60;
		}

        //copy Node Value From Other Node

		__host__ void CopyFrom(PDPTW::CustomerNode *OtherNode) {

			this->CustomerNodeStationID = OtherNode->CustomerNodeStationID;
			this->UserID              = OtherNode->UserID;
			this->NodeDemand          = OtherNode->NodeDemand;
			this->UserAction          = OtherNode->UserAction;
			this->NodeArriveTime      = OtherNode->NodeArriveTime;
			this->NodeTimeWindowLeft  = OtherNode->NodeTimeWindowLeft;
			this->NodeTimeWindowRight = OtherNode->NodeTimeWindowRight;
		}

		//Copy Node Value to other Node
		__host__ void CopyTo(PDPTW::CustomerNode *OtherNode) {

			OtherNode->CustomerNodeStationID = this->CustomerNodeStationID;
			OtherNode->UserID                = this->UserID;
			OtherNode->NodeDemand            = this->NodeDemand;
			OtherNode->UserAction            = this->UserAction;
			OtherNode->NodeArriveTime        = this->NodeArriveTime;
			OtherNode->NodeTimeWindowLeft    = this->NodeTimeWindowLeft;
			OtherNode->NodeTimeWindowRight   = this->NodeTimeWindowRight;
		}

		//set Node to Null 
		__host__ void SetNull() {

			this->CustomerNodeStationID      = 0;
			this->UserID                     = 0;
			this->NodeDemand                 = 0;
			this->UserAction                 = false;
			this->NodeArriveTime             = PDPTW::maxTime;
			this->NodeTimeWindowLeft         = PDPTW::maxTime;
			this->NodeTimeWindowRight        = PDPTW::maxTime;
		}


		__host__ void SetStartNode() {
			this->CustomerNodeStationID = 0;
			this->UserID                = 0;
			this->NodeDemand            = 0;
			this->UserAction            = false;
			this->NodeArriveTime        = PDPTW::maxTime;
			this->NodeTimeWindowLeft    = PDPTW::maxTime;
			this->NodeTimeWindowRight   = PDPTW::maxTime;
		}

		__host__ void SetEndNode() {
			this->CustomerNodeStationID = 0;
			this->UserID                = 0;
			this->NodeDemand            = 0;
			this->UserAction            = false;
			this->NodeArriveTime        = PDPTW::maxTime;
			this->NodeTimeWindowLeft    = PDPTW::maxTime;
			this->NodeTimeWindowRight   = PDPTW::maxTime;
		}
		//toString
		void toString(char *S) {
			sprintf(S, "{addressID:%d,userID:%d,isUp:%d,arrTime:%.0f,leaTime:%.0f}",this->CustomerNodeStationID,this->UserID,this->UserAction,this->NodeTimeWindowLeft,this->NodeTimeWindowRight);
		}


	};






}