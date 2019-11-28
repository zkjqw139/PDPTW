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

//公司工厂 
//提供建议决策树决定工厂类型
//小公司 -> 公司到达率小于一个固定的阈值，能被三个班次满足，并且在每一个班次中都小于额定载客率 50%
//中公司 -> 公司客流能否被三个班次满足 
//大公司 -> 公司客流无法被三个班次满足
//给定公司计算 公司的每个时刻用户到达数目
//对于小公司和中等的公司，假设是由于我们选择的时间来改变用户习惯
//对于每一辆车 允许最多超载10% 但是超过部分会给予惩罚，并且开通线路需要达到最小用户数目


namespace PDPTW {

	//公司类型
	//通过不同公司的需求上车人数，决定公司类型以及接驳方案
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


	//企业工厂
	//输入企业得到早高峰时段的企业类型
	//企业时刻客流分布

	__host__ PDPTW::CompanyWithTimeTable companyFactory(PDPTW::company comp,std::map<int,float> flowPercent) {
		
		//悲观的假设
		int  nodeDemand = comp.employeeNum / 15;
		comp.employeeWantUseBusNum = nodeDemand;

	 

		//简易决策树决定公司类型
		float companyType=companyTypeDecision(comp);
		//统计公司的客流到达频率
		std::deque<PDPTW::stationNode> pipeflow;
		std::map<int, int> companyflow;
		std::map<int, int> waitflow;
		if (companyType == 0) {
			
			//15分钟的客流
			int  flow1 = 0.2*nodeDemand;
			//30分钟的客流
			int  flow2 = 0.35*nodeDemand;
			//45分钟的客流
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

		//为公司绑上各个时刻的客流
		PDPTW::CompanyWithTimeTable COMPWT(comp.name, comp.lon, comp.lat, comp.employeeNum, nodeDemand, companyType);
		COMPWT.timeflow = companyflow;
		COMPWT.DemandInStation = waitflow; 
		
		if (companyType > 0 ) {
			sort(pipeflow.begin(), pipeflow.end(),PDPTW::compareStationNode);
			COMPWT.pipeflow = pipeflow;
		}

		return COMPWT;
	}

	//生成站点流量序列表
	__host__  std::deque<int> stationFlowGenerate(PDPTW::company comp, std::map<int, float> flowPercent) {

		//悲观的假设
		float  nodeDemand = comp.employeeNum / 15;
		comp.employeeWantUseBusNum = nodeDemand;

		//简易决策树决定公司类型
		float companyType = companyTypeDecision(comp);
		//统计公司的客流到达频率
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


	//将大公司直接插入线路集合上
	__host__ std::vector<int>  createLargeCompanyRoute(PDPTW::company comp, std::map<int, float> flowPercent) {

		//悲观的假设
		float  nodeDemand = comp.employeeNum/10;
		comp.employeeWantUseBusNum = nodeDemand;

		//简易决策树决定公司类型
		float companyType = companyTypeDecision(comp);
		//统计公司的客流到达频率
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