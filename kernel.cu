#pragma  once
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <cuda.h>
#include "loadData.h"
#include "BaseInitOp.cuh"
#include "evaluate.cuh"
#include "RemoveOP.cuh"
#include "InsertOp.cuh"
#include "critetionOp.cuh"
#include "OptimalOp.cuh"
#include "loadDataFrame.cuh"
#include "stdlib.h"
#include <stdio.h>
#include <io.h>
#include <string>

#include "process.h"
#include "spyderMetroData.cuh"
#include "Companyfactory.cuh"
#include "curl/curl.h"

#include "request.h"
#include "Dispatch.h"
#include "dispatchTest.cuh"


#include "ALNS.cuh"
#include "Route.cuh"
#include "msgpack.hpp"
#include <sstream>
#include <fstream>
#include <Eigen/Dense>

#include "MCTBase.cuh"
#include "mctBaseTest.cuh"
#include <typeinfo>

//云接驳问题
//对于云接驳问题，是一个所有需求都在场站，所有D在各个公司位置的,VRP问题
//对于云接驳问题需要定义的目标函数
//配车固定成本*配车数目+sum(每辆车的移动距离*发车动态成本)+（sum(单客户等待时间的类指数函数))
//目标是最小化这个解
//约束条件
//车辆约束
//1.车辆开行时间<30min
//2.3km <车辆开行距离<20km
//3.40人<车辆容量限制<60人
//4.车辆允许一定程度的超载但是会加上惩罚
//轨迹约束
//5.对于每一个线路所有站点至少到达一次
//6.所有车辆都是从地铁站出发再回到地铁站

//上一圈运行对下一圈的影响
//决策过程
//每12分钟统计地铁站到所有已知公交站点的OD
//时刻 状态 OD对的问题
//线路不定


//双层规划模型
//超载直达
//用户等待时间的问题
//用户等待时间计算

void showPipeFlow(std::vector<PDPTW::CompanyWithTimeTable> largeCompanys) {

	for (int i = 1; i < largeCompanys.size(); i++) {

		std::cout << largeCompanys[i].name << std::endl;
		for (int j = 0; j < largeCompanys[i].pipeflow.size(); j++) {

			std::cout << largeCompanys[i].pipeflow[j].waitDemand << "   ";

			
		}
		std::cout << std::endl;
	}


}


//读档
PDPTW::Route  readRoute(std::string FileName,int rtype,int timeid) {


	ifstream ism(FileName);
	std::string line;
	int count = 0;

	//线路基本信息
	std::vector<int>  nodeIDs;                 //线路上所有需要到达的站点


	int  routeCount=0;                         //当前线路经过的公司数目
	int  routeDistance=0;                      //线路里程数
	int  routeSingleDistance=0;

	int  routeDuration=0;                      //线路行驶时间
	int  routeSingleDuration=0;

	int  routeType = rtype;                    //type 0:高频率频繁发车
											   //type 1:定时发车


	std::vector<int>  stationWaitFlow;
	std::stringstream iss;

	while (std::getline(ism, line)) {
	    
		if(count==0)
			routeCount = stoi(line);

		 
		if (count == 1)
			routeDistance = stoi(line);
			
		if (count == 2)
			routeSingleDistance = stoi(line);
			
		if (count == 3)
			routeDuration = stoi(line);
			
		if (count == 4)
			routeSingleDuration = stoi(line);
			
		if (count == 5)
			routeType = stoi(line);
			
		if (count == 6) {
			std::stringstream iss(line);
			int number;
			while (iss >> number) {
				nodeIDs.push_back(number);
			}

		}
		if (count == 7){
			std::stringstream iss(line);
			int number;
			while (iss >> number) {
				stationWaitFlow.push_back(number);
			}
		}


		count = count + 1;
	}

	

	PDPTW::Route newRoute(nodeIDs, routeCount, routeDistance, routeSingleDistance, routeDuration, routeSingleDuration, routeType, stationWaitFlow, timeid);
	//newRoute.readShow();
	return newRoute;

}

//函数用来遍历文件夹
//并且寻找需要使用的文件
std::vector<PDPTW::Route> travelFile(std::string FileName, std::string parentFileName){

	std::vector<PDPTW::Route> routePool;
	//用于查找的句柄
	long    handle;
	struct  _finddata_t fileinfo;
	//第一次查找
	handle = _findfirst(FileName.c_str(), &fileinfo);
	


	if (handle == -1) {
		std::cout << "no file found" << std::endl;
		return routePool;
	}

	while (!_findnext(handle, &fileinfo)){
		std::string originFileName = parentFileName + fileinfo.name;
	    
		int rtype = 0;

		if (fileinfo.name[0] != 's') {
			rtype = 0;
		}
		else {
			rtype = 1;
		}


		int timeid = 0;
		if (rtype == 0) {
			timeid = (fileinfo.name[0]-'0');
		}
		else {
			timeid = -1;
		}


		PDPTW::Route newRoute = readRoute(originFileName, rtype, timeid);
		routePool.push_back(newRoute);
	} 

	_findclose(handle);
	return routePool;
}


int main()
{   
	//载入公司
	std::string  filename = "C:/Users/hasee/Documents/Visual Studio 2015/Projects/PDPTW/DataSrc/西兴地铁站接驳车站点统计.csv";
	vector<PDPTW::company> companys=PDPTW::loadDF(filename);
	
	

	std::string metro_station_name = "'西兴站'";
	std::string hour_begin = "8";
	std::string hour_end = "9";
	std::string day_begin = "20190301";
	std::string day_end = "20190401";
	
	
	
	map<int, float> flowPercent = PDPTW::metroFlowDistribution();
	std::vector<PDPTW::station> stationPool;

	//对于不同公司类型生成不同的矩阵用于计算公司类型
	std::string origins = "120.220429,30.187295";
	std::string dest = "120.189549,30.190514";
	std::string name = "西兴";
	PDPTW::CompanyWithTimeTable depot(name, 120.220429, 30.187295, 0, 0, -1);

	std::vector<PDPTW::CompanyWithTimeTable> smallCompanys;
	std::vector<PDPTW::CompanyWithTimeTable> largeCompanys;
	smallCompanys.push_back(depot);
	largeCompanys.push_back(depot);


	std::vector<PDPTW::CompanyWithTimeTable> companyWithTimeWindows;
	for (int i = 0; i < companys.size(); i++) {
		companyWithTimeWindows.push_back(PDPTW::companyFactory(companys[i], flowPercent));
	}
	
	//建立ID与站点名称的对应关系
	std::map<int, std::string> smallCompanyID2Name;
	std::map<int, std::string> largeCompanyID2Name;
	std::map<std::string, int>  companysName2ID;

	for (int i = 0; i < companyWithTimeWindows.size(); i++) {
		if (companyWithTimeWindows[i].companyType == 0) {
			smallCompanys.push_back(companyWithTimeWindows[i]);

		}
		else {
			largeCompanys.push_back(companyWithTimeWindows[i]);
		}
	}

	//字典生成
	for (int i = 0; i < smallCompanys.size(); i++) {
		std::string name = smallCompanys[i].name;
		int  index = i;
		smallCompanyID2Name.insert(pair<int, std::string>(i, name));
	}
	
	for (int i = 0; i < largeCompanys.size(); i++) {
		std::string name = largeCompanys[i].name;
		int index = i;
		largeCompanyID2Name.insert(pair<int, std::string>(i, name));
	}

	for (int i = 0; i < companys.size(); i++) {
		std::string name = companys[i].name;
		int index = i;
		companysName2ID.insert(pair<std::string, int>(name, i));
	}

	//遍历文件夹
	std::string fileName = "route\\*";
	std::string parentFileName = "route\\";
	std::vector<PDPTW::Route> routePool = travelFile(fileName, parentFileName);


	for (int i = 0; i < companys.size(); i++) {
		std::deque<int>  flow = PDPTW::stationFlowGenerate(companys[i], flowPercent);
		std::string  name = companys[i].name;
		companys[i].employeeWantUseBusNum = companys[i].employeeNum / 15;
		int companyType = PDPTW::companyTypeDecision(companys[i]);
    
		PDPTW::station oneStation(name, flow, companyType);
		stationPool.push_back(oneStation);
		if (companyType == 2) {
			std::string destination = to_string(companys[i].lon) + "," + to_string(companys[i].lat);
			PDPTW::disInfo dinfo =PDPTW::getAllDistanceAndDuration(origins, destination);

			int  dist = dinfo.circleDistance;
			int  singleDist = dinfo.metroToDestDistance;

			int  duration = dinfo.circleDuration;
			int  singleDuration = dinfo.metroToDestDuration;

			int  routeCount = 1;

			std::vector<int> stationflow = PDPTW::createLargeCompanyRoute(companys[i], flowPercent);
			std::vector<int> nodIDS;

			nodIDS.push_back(i);


			PDPTW::Route largeCompanyRoute(nodIDS, 1, dist, singleDist, duration, singleDuration, 2, stationflow, -2);
			routePool.push_back(largeCompanyRoute);
		}
	}

	//ID转换
	for (int i = 0; i < routePool.size(); i++) {

		std::vector<int> routeIDs = routePool[i].nodeIDs;

		int routeType = routePool[i].routeType;
		if (routeType == 0) {

			for (int j = 0; j < routeIDs.size(); j++) {

				int rid = routeIDs[j];
				std::string newName = largeCompanyID2Name.at(rid);
				int newid = companysName2ID.at(newName);
				routeIDs[j] = newid;
			}			
			routePool[i].nodeIDs = routeIDs;
		}

		else if (routeType == 1) {

			for (int j = 0; j < routeIDs.size(); j++) {

				int rid = routeIDs[j];
				std::string newName = smallCompanyID2Name.at(rid);
				int newid = companysName2ID.at(newName);
				routeIDs[j] = newid;
			}
			routePool[i].nodeIDs = routeIDs;
		}
	}

	//生成客流棋盘

	int segLength  = routePool.size(); //线路数目
	int timeLength = 30;               //决策时刻数目

	//棋盘生成
	Eigen::MatrixXd boardTable=Eigen::MatrixXd::Zero(segLength, timeLength);
	for (int i = 0; i < routePool.size(); i++) {	
		vector<int> stationWaitFlow = routePool[i].stationWaitFlow;
		for (int j = 0; j < stationWaitFlow.size(); j++) {
			boardTable(i, j) = stationWaitFlow[j];
		}
	}

	//站点客流生成
	std::vector<int> stationWaitFlow;
	for (int i = 0; i < companys.size(); i++) {
		stationWaitFlow.push_back(companys[i].employeeWantUseBusNum);
	}

	for (int i = 0; i < routePool.size(); i++) {
		routePool[i].setComapnyPercent(companys);
	} 
	
	//公司线路映射字典生成
	std::map<int, std::vector<int>> companytypeRouteDict; // 公司类型路线ID字典
	std::vector<int>  smallcompanyRouteID;                // 小公司线路ID
	std::vector<int>  largecompanyRouteID;                // 大公司线路ID
	std::vector<int>  middlecompanyRouteID;               // 中公司线路ID

	for (int i = 0; i < routePool.size(); i++) {
		if (routePool[i].routeType == 0) {
			middlecompanyRouteID.push_back(i);
		}
		else if (routePool[i].routeType == 1) {
			smallcompanyRouteID.push_back(i);
		}
		else if (routePool[i].routeType == 2) {
			largecompanyRouteID.push_back(i);
		}
	}
	 
	companytypeRouteDict.insert(std::pair<int, std::vector<int>>(0, middlecompanyRouteID));
	companytypeRouteDict.insert(std::pair<int, std::vector<int>>(2, largecompanyRouteID));
	companytypeRouteDict.insert(std::pair<int, std::vector<int>>(1, smallcompanyRouteID));
	MCT::Board  newBoard(boardTable, stationWaitFlow);
	MCT::Agent  agent;
	MCT::BusPot pot;

	//贪婪搜索
	agent.BaseGreedySearch(newBoard, pot, companytypeRouteDict, routePool, true);
    

	system("pause");
    return 0;
}

 