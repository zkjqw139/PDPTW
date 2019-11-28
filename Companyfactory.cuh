#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include <cublas.h>
#include <string>
#include <algorithm>
#include <map>
#include <deque>
#include "company.cuh"

//��˾���� 
//�ṩ���������������������
//С��˾ -> ��˾������С��һ���̶�����ֵ���ܱ�����������㣬������ÿһ������ж�С�ڶ�ؿ��� 50%
//�й�˾ -> ��˾�����ܷ������������ 
//��˾ -> ��˾�����޷��������������
//������˾���� ��˾��ÿ��ʱ���û�������Ŀ
//����С��˾���еȵĹ�˾����������������ѡ���ʱ�����ı��û�ϰ��
//����ÿһ���� ������೬��10% ���ǳ������ֻ����ͷ������ҿ�ͨ��·��Ҫ�ﵽ��С�û���Ŀ


namespace PDPTW {

	//��˾����
	//ͨ����ͬ��˾�������ϳ�������������˾�����Լ��Ӳ�����
	__host__ float companyTypeDecision(PDPTW::company comp) {
		
		float companyType = 0;

		if (comp.employeeWantUseBusNum < 64 && comp.employeeWantUseBusNum>0) {
			companyType = 0;
		}
		else if(comp.employeeWantUseBusNum >= 64 && comp.employeeWantUseBusNum < 100) {
			companyType = 1;
		}
		else if (comp.employeeWantUseBusNum >= 100) {
			companyType = 2;
		}

		return companyType;
	}


	//��ҵ����
	//������ҵ�õ���߷�ʱ�ε���ҵ����
	//��ҵʱ�̿����ֲ�

	__host__ PDPTW::CompanyWithTimeTable companyFactory(PDPTW::company comp,std::map<int,float> flowPercent) {
		
		//���۵ļ���
		int  nodeDemand = comp.employeeNum / 15;
		comp.employeeWantUseBusNum = nodeDemand;

	 

		//���׾�����������˾����
		float companyType=companyTypeDecision(comp);
		//ͳ�ƹ�˾�Ŀ�������Ƶ��
		std::deque<PDPTW::stationNode> pipeflow;
		std::map<int, int> companyflow;
		std::map<int, int> waitflow;
		if (companyType == 0) {
			
			//15���ӵĿ���
			int  flow1 = 0.2*nodeDemand;
			//30���ӵĿ���
			int  flow2 = 0.35*nodeDemand;
			//45���ӵĿ���
			int  flow3 = 0.45*nodeDemand;

			companyflow.insert(std::pair<int, int>(3, flow1));
			companyflow.insert(std::pair<int, int>(6, flow2));
			companyflow.insert(std::pair<int, int>(9, flow3));

			waitflow.insert(std::pair<int, int>(3, flow1));
			waitflow.insert(std::pair<int, int>(6, flow1+flow2));
			waitflow.insert(std::pair<int, int>(9, flow1 + flow2+flow3));

			
		}
		else if (companyType == 1) {

			std::map<int, float>::iterator it = flowPercent.begin();

			int   sum = 0;
			float prepercent = 0;
			for (it = flowPercent.begin(); it != flowPercent.end(); it++) {

				int   timeid = it->first;
				float percent = it->second;
				

				int   flownum = percent*nodeDemand;
				sum = sum + flownum;

				companyflow.insert(std::pair<int, int>(timeid, flownum));
				waitflow.insert(std::pair<int, int>(timeid, sum));

				int duration = (timeid + 1) * 300;

				if (timeid % 2 == 0) {
					PDPTW::stationNode snode1;
					snode1.timeid = duration;
					snode1.waitDemand = flownum;
					pipeflow.push_back(snode1);
					prepercent = percent;
				}
				else if (timeid % 2 == 1) {

					PDPTW::stationNode snode1;
					snode1.timeid = duration;
					snode1.waitDemand = flownum + nodeDemand*prepercent;
					pipeflow.push_back(snode1);
					prepercent = percent;

				}
			}

		}
		else if (companyType == 2) {


			int  nodeDemand = comp.employeeNum / 10;
			comp.employeeWantUseBusNum = nodeDemand;

			std::map<int, float>::iterator it = flowPercent.begin();

			int sum = 0;
			float prepercent = 0;
			for (it = flowPercent.begin(); it != flowPercent.end(); it++) {

				int   timeid = it->first;
				float percent = it->second;

				int   flownum = percent*nodeDemand;
				sum = sum + flownum;
				
				companyflow.insert(std::pair<int, int>(timeid, flownum));
				waitflow.insert(std::pair<int, int>(timeid, sum));

				int duration = (timeid+1)* 300;
				
				if (timeid % 2 == 0) {
					PDPTW::stationNode snode1;
					snode1.timeid = duration;
					snode1.waitDemand = flownum;
					pipeflow.push_back(snode1);
					prepercent = percent;
				}
				else if (timeid % 2 == 1) {

					PDPTW::stationNode snode1;
					snode1.timeid = duration;
					snode1.waitDemand = flownum + nodeDemand*prepercent;
					pipeflow.push_back(snode1);
					prepercent = percent;

				}
				 
			}
		}

		//Ϊ��˾���ϸ���ʱ�̵Ŀ���
		PDPTW::CompanyWithTimeTable COMPWT(comp.name, comp.lon, comp.lat, comp.employeeNum, nodeDemand, companyType);
		COMPWT.timeflow = companyflow;
		COMPWT.DemandInStation = waitflow; 
		
		if (companyType > 0 ) {
			sort(pipeflow.begin(), pipeflow.end(),PDPTW::compareStationNode);
			COMPWT.pipeflow = pipeflow;
		}

		return COMPWT;
	}

	//����վ���������б�
	__host__  std::deque<int> stationFlowGenerate(PDPTW::company comp, std::map<int, float> flowPercent) {

		//���۵ļ���
		float  nodeDemand = comp.employeeNum / 15;
		comp.employeeWantUseBusNum = nodeDemand;

		//���׾�����������˾����
		float companyType = companyTypeDecision(comp);
		//ͳ�ƹ�˾�Ŀ�������Ƶ��
		std::deque<int> pipeflow;
		std::map<int, float>::iterator it = flowPercent.begin();

		float   sum = 0;
		float prepercent = 0;
		for (it = flowPercent.begin(); it != flowPercent.end(); it++) {

				int   timeid = it->first;
				float percent = it->second;


				float   flownum = percent*nodeDemand;
				sum = sum + flownum;
				pipeflow.push_back(sum);
		}

 

		return pipeflow;
	}


	//����˾ֱ�Ӳ�����·������
	__host__ std::vector<int>  createLargeCompanyRoute(PDPTW::company comp, std::map<int, float> flowPercent) {

		//���۵ļ���
		float  nodeDemand = comp.employeeNum/10;
		comp.employeeWantUseBusNum = nodeDemand;

		//���׾�����������˾����
		float companyType = companyTypeDecision(comp);
		//ͳ�ƹ�˾�Ŀ�������Ƶ��
		std::vector<int> pipeflow;
		std::map<int, float>::iterator it = flowPercent.begin();

		float sum = 0;

		for (it = flowPercent.begin(); it != flowPercent.end(); it++) {

			int   timeid = it->first;
			float percent = it->second;

			float   flownum = percent*nodeDemand;
			pipeflow.push_back(sum + flownum/2);
			sum = sum + flownum;			
			pipeflow.push_back(sum);
		}

		return pipeflow;



	}

}