#pragma  once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cublas.h>
#include <string>
#include <map>
#include <deque>

namespace PDPTW {

	struct stationNode {
		int timeid;
		int waitDemand;
	};  

	bool compareStationNode(stationNode& a, stationNode & b) {
		return a.timeid < b.timeid;
	}

	struct busNode {

		//��ǰ�����ķ���ʱ��
		//��ǰ����������ؿ���
		//��ǰ���������������Ŀ
		int  arrivetime;
		int  busDemand;
		int  currentDemand = 0;
		int  TravelDistance;
		bool isLast;
	};

	bool compareBusNode(busNode& a, busNode & b) {
		return a.arrivetime < b.arrivetime;
	}

	class company {


	public:
		company() {

			name = "������ ";
			lon = 0.0;
			lat = 0.0;
			employeeNum = 9999999;
			employeeWantUseBusNum = 0;
		}


		company(std::string name, float lon, float lat, int employeeNum, int employeeWantUseBusNum) {

			this->name = name;
			this->lon = lon;
			this->lat = lat;
			this->employeeNum = employeeNum;
			this->employeeWantUseBusNum = employeeWantUseBusNum;
		}


		std::string  name;
		float        lon;
		float        lat;
		int          employeeNum;
		int          employeeWantUseBusNum;

	};


	class CompanyWithTimeTable:public company {

		  
	public:

		CompanyWithTimeTable(std::string name, float lon,float lat, int employeenum, int employeeWantUseBuSNum,int companyType) {

			this->name = name;
			this->lon  = lon;
			this->lat  = lat;
			this->employeeNum = employeenum;
			this->employeeWantUseBusNum = employeeWantUseBuSNum;
			this->companyType = companyType;
		}


		int companyType;                              //��ʾ��˾���ͣ���Ϊ��˾�����͹�˾���Լ�С��˾
 		std::map<int, int> timeflow;                  //ʱ�̱��ʾÿ����ӵ�����û�
		                                              //���ֵ��ʾ�û�������
		std::map<int, int>  DemandInStation;          //��ʾÿһ��ʱ��������վ���ϵȴ����û�
		 
		std::deque<stationNode> pipeflow;             //�û�ˮ�ܣ����Լ�����ۺ���
	};

	struct station {
		std::string name;
		std::deque<int> flow;
		int companyType;

		station(std::string name, std::deque<int> flow, int companyType) {

			this->name = name;
			this->flow = flow;
			this->companyType = companyType;

		}

		void show() {

			std::cout << this->name << std::endl;
			std::cout << this->companyType << std::endl;

			for (int i = 0; i < this->flow.size(); i++) {
				std::cout << this->flow[i] << " ";
			}
			std::cout << std::endl;

		}


	};

}




