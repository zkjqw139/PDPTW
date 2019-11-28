#pragma once
#include "curl/curl.h"
#include "cjson\cJSON.h"
#include <iostream>
#include <stdio.h>
#include <vector>
#include <algorithm>
#include <time.h>
#include <iostream>
#include "coeff.cuh"
#include "request.h"
#include "evaluate.cuh"

//��ҪĿ����
//������ʱ�̱�ת��Ϊ��վʱ������

namespace PDPTW {

	std::vector<PDPTW::busNode> dispatchToArriveTimeTable(std::vector<PDPTW::dfsComponent> dispatchTable,PDPTW::disInfo dinfo) {
        
		std::vector<PDPTW::busNode> arriveTimeTable;
		for (int i = 0; i < dispatchTable.size(); i++) {

			//��ȷ������ʱ
			if (dispatchTable[i].ifDispatch == true) {
				int time = dispatchTable[i].DispatchTime;
				int dist = dinfo.circleDistance;
				while (time <3600-dinfo.metroToDestDuration ) {
					
					PDPTW::busNode bnode;
					bnode.arrivetime  = time;
					bnode.TravelDistance = dist;
					bnode.busDemand   = 60;
					bnode.currentDemand = 0;

					int temp_time = time;

					bnode.isLast = false;

					//����Ա���ԣ����Գٵ�
					if (temp_time + dinfo.metroToDestDuration+dinfo.circleDuration>=3600) {
						bnode.isLast = true;
						arriveTimeTable.push_back(bnode);
						break;
					}
					
					arriveTimeTable.push_back(bnode);

					time = time + dinfo.circleDuration;
					dist = dist + dinfo.circleDistance;
					
				}
			}
		}

		sort(arriveTimeTable.begin(), arriveTimeTable.end(),PDPTW::compareBusNode);
		return arriveTimeTable;
	}


	//�򵥵����ɵ�վʱ�̱�ֻ���Ƿ���ʱ��
	std::vector<PDPTW::busNode> simpleDispatchToArriveTimeTable(std::vector<PDPTW::dfsComponent> dispatchTable, PDPTW::disInfo dinfo) {

		std::vector<PDPTW::busNode> arriveTimeTable;
		for (int i = 0; i < dispatchTable.size(); i++) {

			//��ȷ������ʱ
			if (dispatchTable[i].ifDispatch == true) {
				int time = dispatchTable[i].DispatchTime;
				int dist = dinfo.circleDistance;
				 

				PDPTW::busNode bnode;
				bnode.arrivetime = time;
				bnode.TravelDistance = dist;
				bnode.busDemand = 60;
				bnode.currentDemand = 0;

				int temp_time = time;

				bnode.isLast = false;

				//����Ա���ԣ����Գٵ�
				if (temp_time + dinfo.metroToDestDuration + dinfo.circleDuration >= 3600) {
						bnode.isLast = true;
				}

				arriveTimeTable.push_back(bnode);
			}
		}

		sort(arriveTimeTable.begin(), arriveTimeTable.end(), PDPTW::compareBusNode);
		return arriveTimeTable;
	}



}