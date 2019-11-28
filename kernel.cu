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

//�ƽӲ�����
//�����ƽӲ����⣬��һ�����������ڳ�վ������D�ڸ�����˾λ�õ�,VRP����
//�����ƽӲ�������Ҫ�����Ŀ�꺯��
//�䳵�̶��ɱ�*�䳵��Ŀ+sum(ÿ�������ƶ�����*������̬�ɱ�)+��sum(���ͻ��ȴ�ʱ�����ָ������))
//Ŀ������С�������
//Լ������
//����Լ��
//1.��������ʱ��<30min
//2.3km <�������о���<20km
//3.40��<������������<60��
//4.��������һ���̶ȵĳ��ص��ǻ���ϳͷ�
//�켣Լ��
//5.����ÿһ����·����վ�����ٵ���һ��
//6.���г������Ǵӵ���վ�����ٻص�����վ

//��һȦ���ж���һȦ��Ӱ��
//���߹���
//ÿ12����ͳ�Ƶ���վ��������֪����վ���OD
//ʱ�� ״̬ OD�Ե�����
//��·����


//˫��滮ģ��
//����ֱ��
//�û��ȴ�ʱ�������
//�û��ȴ�ʱ�����

void showPipeFlow(std::vector<PDPTW::CompanyWithTimeTable> largeCompanys) {

	for (int i = 1; i < largeCompanys.size(); i++) {

		std::cout << largeCompanys[i].name << std::endl;
		for (int j = 0; j < largeCompanys[i].pipeflow.size(); j++) {

			std::cout << largeCompanys[i].pipeflow[j].waitDemand << "   ";

			
		}
		std::cout << std::endl;
	}


}


//����
PDPTW::Route  readRoute(std::string FileName,int rtype,int timeid) {


	ifstream ism(FileName);
	std::string line;
	int count = 0;

	//��·������Ϣ
	std::vector<int>  nodeIDs;                 //��·��������Ҫ�����վ��


	int  routeCount=0;                         //��ǰ��·�����Ĺ�˾��Ŀ
	int  routeDistance=0;                      //��·�����
	int  routeSingleDistance=0;

	int  routeDuration=0;                      //��·��ʻʱ��
	int  routeSingleDuration=0;

	int  routeType = rtype;                    //type 0:��Ƶ��Ƶ������
											   //type 1:��ʱ����


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

//�������������ļ���
//����Ѱ����Ҫʹ�õ��ļ�
std::vector<PDPTW::Route> travelFile(std::string FileName, std::string parentFileName){

	std::vector<PDPTW::Route> routePool;
	//���ڲ��ҵľ��
	long    handle;
	struct  _finddata_t fileinfo;
	//��һ�β���
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
	//���빫˾
	std::string  filename = "C:/Users/hasee/Documents/Visual Studio 2015/Projects/PDPTW/DataSrc/���˵���վ�Ӳ���վ��ͳ��.csv";
	vector<PDPTW::company> companys=PDPTW::loadDF(filename);
	
	

	std::string metro_station_name = "'����վ'";
	std::string hour_begin = "8";
	std::string hour_end = "9";
	std::string day_begin = "20190301";
	std::string day_end = "20190401";
	
	
	
	map<int, float> flowPercent = PDPTW::metroFlowDistribution();
	std::vector<PDPTW::station> stationPool;

	//���ڲ�ͬ��˾�������ɲ�ͬ�ľ������ڼ��㹫˾����
	std::string origins = "120.220429,30.187295";
	std::string dest = "120.189549,30.190514";
	std::string name = "����";
	PDPTW::CompanyWithTimeTable depot(name, 120.220429, 30.187295, 0, 0, -1);

	std::vector<PDPTW::CompanyWithTimeTable> smallCompanys;
	std::vector<PDPTW::CompanyWithTimeTable> largeCompanys;
	smallCompanys.push_back(depot);
	largeCompanys.push_back(depot);


	std::vector<PDPTW::CompanyWithTimeTable> companyWithTimeWindows;
	for (int i = 0; i < companys.size(); i++) {
		companyWithTimeWindows.push_back(PDPTW::companyFactory(companys[i], flowPercent));
	}
	
	//����ID��վ�����ƵĶ�Ӧ��ϵ
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

	//�ֵ�����
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

	//�����ļ���
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

	//IDת��
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

	//���ɿ�������

	int segLength  = routePool.size(); //��·��Ŀ
	int timeLength = 30;               //����ʱ����Ŀ

	//��������
	Eigen::MatrixXd boardTable=Eigen::MatrixXd::Zero(segLength, timeLength);
	for (int i = 0; i < routePool.size(); i++) {	
		vector<int> stationWaitFlow = routePool[i].stationWaitFlow;
		for (int j = 0; j < stationWaitFlow.size(); j++) {
			boardTable(i, j) = stationWaitFlow[j];
		}
	}

	//վ���������
	std::vector<int> stationWaitFlow;
	for (int i = 0; i < companys.size(); i++) {
		stationWaitFlow.push_back(companys[i].employeeWantUseBusNum);
	}

	for (int i = 0; i < routePool.size(); i++) {
		routePool[i].setComapnyPercent(companys);
	} 
	
	//��˾��·ӳ���ֵ�����
	std::map<int, std::vector<int>> companytypeRouteDict; // ��˾����·��ID�ֵ�
	std::vector<int>  smallcompanyRouteID;                // С��˾��·ID
	std::vector<int>  largecompanyRouteID;                // ��˾��·ID
	std::vector<int>  middlecompanyRouteID;               // �й�˾��·ID

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

	//̰������
	agent.BaseGreedySearch(newBoard, pot, companytypeRouteDict, routePool, true);
    

	system("pause");
    return 0;
}

 