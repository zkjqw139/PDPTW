#pragma once
#include<iostream>
#include<stdio.h>
#include<vector>
#include<Eigen/Dense>
#include"Route.cuh"
#include<map>
#include<math.h>
#include"util.cuh"

//MCT �������ݽṹ
namespace MCT {


	struct move {
		int timeid_x;
		int routeSelct_y;

		move() {
			timeid_x = 0;
			routeSelct_y = 0;
		}

		move(int x, int y) {
			timeid_x = x;
			routeSelct_y = y;
		}

		bool operator<(const move & b)  const {

			if (timeid_x < b.timeid_x)
				return true;
			else if (timeid_x > b.timeid_x) {
				return false;
			}
			else {

				if (routeSelct_y < b.routeSelct_y) {
					return true;
				}
				else {
					return false;
				}
			}

		}

		bool operator==(const move & b) const {
			return (routeSelct_y == b.routeSelct_y) && (timeid_x ==timeid_x);
		}
	};


	//��������
	class Board {


	public:

		Board() {

		}

		Board(Eigen::MatrixXf  boardTable,std::vector<int> totalStationWaitFlow) {
			this->boardTable = boardTable;

			for (int i = 0; i < boardTable.rows(); i++) {
				this->hasBusArrived.push_back(false);
			}
			this->totalStationWaitFlow = totalStationWaitFlow;
		};

		void showBoard() {
			std::cout << this->boardTable << std::endl;
		}

		void setLineToZero(int timeID) {

			for (int i = 0; i < this->boardTable.rows(); i++) {
				this -> boardTable(i, timeID) = 0;
			 }
			
		}
        
		std::vector<float> getState(int timeID) {

			std::vector<float> state;
			for (int i = 0; i < this->boardTable.rows(); i++) {
				state.push_back(boardTable(i, timeID));
			}

			return state;
		}

		//��������
		void updateBoard(std::vector<PDPTW::Route> RoutePool,move onemove,int busLoadLimit)  {

			int timeid = onemove.timeid_x;
			int lineid = onemove.routeSelct_y;



			if (RoutePool[lineid].routeType == 0 || RoutePool[lineid].routeType == 2) {
 

				std::vector<int> nodeIDs = RoutePool[lineid].nodeIDs;
				std::map<int, float> percent = RoutePool[lineid].companyPercent;

				int  getDemand = 0;

				int currDemand = this->boardTable(lineid, timeid);

				if (currDemand < busLoadLimit) {
					getDemand = currDemand;
				}
				else {
					getDemand = busLoadLimit;
				}	
				
				for (int i = 0; i < nodeIDs.size(); i++) {
					int id = nodeIDs[i];
					
					 

					float pre = this->totalStationWaitFlow[id];



					this->totalStationWaitFlow[id]  -= abs(percent.at(id))*abs(getDemand);

					if (this->totalStationWaitFlow[id] > 0 && nodeIDs.size()>1) {
						this->totalStationWaitFlow[id]+=1;
					}


					this->totalStationWaitFlow[id]   = max(0, this->totalStationWaitFlow[id]);
					float curr = this->totalStationWaitFlow[id];			
				}

 
				for (int i = 1; i < this->boardTable.rows(); i++) {
					int num = checKRoute(RoutePool[i], nodeIDs, percent, getDemand);
					updateLine(timeid, i, num);
				}

			 
				this->hasBusArrived[lineid] = true;
			}
			else {

				std::vector<int> nodeIDs = RoutePool[lineid].nodeIDs;
				
				for (int i = 0; i < nodeIDs.size(); i++) {

					int id = nodeIDs[i];
					totalStationWaitFlow[id] = 0;

				}
				this->hasBusArrived[lineid] = true;
			}

		}


		int checKRoute(PDPTW::Route route,std::vector<int> nodeIDs, std::map<int, float> percent,int num) {

			float sum = 0;
			for (int i = 0; i < nodeIDs.size(); i++) {

				int ID = nodeIDs[i];

				if (route.checkCompany(ID)) {
					sum = sum + percent.at(ID)*num;

				}
			}
			return sum;
		}


		void updateLine(int timeID,int lineID,float num) {

			for (int i = 0; i < this->boardTable.cols(); i++) {

				this->boardTable(lineID, i) -= num;

				if (this->boardTable(lineID, i) < 0) {
					this->boardTable(lineID, i) = 0;
				}
			}
		}


		//�жϵ�ǰʱ���Ƿ���߽���
		//С��˾ֻ����8��30-8��50�����Ƿ񷢳�
		//��˾�Ĺ�����·ֻ������·����24��ʱ���Ƿ���
		bool islineEnd(std::vector<PDPTW::Route> RoutePool,int timeid) {

			bool lineEnd = true;

			for (int i = 0; i < RoutePool.size(); i++) {

				if (RoutePool[i].routeType == 1) {
					int flow = 3 * (timeid - 12) + 36;
					this->boardTable(i, timeid) = flow;
				}
				

				if (this->boardTable(i, timeid) >= 36) {

					lineEnd = false;

				}
				
			}

			return  lineEnd;
		}
        
		//�ж�������Ϸ�Ƿ����
		//��8��50���ж��Ƿ��˾��ƴ����·�ĵȴ�������С��20
		//�����ж�С��˾���Ѿ��г�����
		bool isGameEnd(std::vector<PDPTW::Route> RoutePool) {
			
			bool GameEnd = true;

			for (int i = 0; i < boardTable.rows(); i++) {

				int rtype = RoutePool[i].routeType;

				if (rtype == 1) {

					if (hasBusArrived[i] == false) {

						GameEnd = false;
					}
				}
				else {
					if (boardTable(i,24) > 24) {

						GameEnd = false;

					}
				}
			}

			return GameEnd;

		}

		std::vector<int> getStationWaitFlow() {
			return this->totalStationWaitFlow;
		}

		Board& operator=(Board& oneBoard) {
			 

		
			std::vector<int>  _totalStationWaitFlow;
			Eigen::MatrixXf  table = oneBoard.getBoardTable();

			int rows = table.rows();
			int cols = table.cols();
            
			this->boardTable = oneBoard.boardTable;

			for (int i = 0; i < oneBoard.totalStationWaitFlow.size(); i++) {
				this->totalStationWaitFlow.push_back(oneBoard.totalStationWaitFlow[i]);
			}

			for (int i = 0; i < table.rows(); i++) {
				this->hasBusArrived.push_back(false);
			}
		    
			return *this;

		}

		//����״��
		//���ڰ���״����˵

		int getBoardCondition() {

			int BoardCondition = 0;
			for (int i = 0; i < totalStationWaitFlow.size(); i++) {
				BoardCondition = BoardCondition + totalStationWaitFlow[i] * 2.5;
			}
			return BoardCondition;
		}


		std::vector<bool> getHasArrived() {
			return hasBusArrived;
		}

		Eigen::MatrixXf getBoardTable() {
			return this->boardTable;
		}

		std::vector<bool> getHasBusArrived() {
			return this->hasBusArrived;
		}

		std::vector<bool> getStationHasArrived() {
			return this->stationHasArrived;
		}

		std::vector<int>  getTotalStationWaitFlow() {
			return this->totalStationWaitFlow;
		}


		~Board() {
		
		};

	
	private:
		Eigen::MatrixXf   boardTable;
		std::vector<bool> hasBusArrived;
		std::vector<bool> stationHasArrived;  
		std::vector<int>  totalStationWaitFlow;
	};


	

	//�����г�����¼
	struct  travel{

		int timeid  = 0;           //����ʱ��
		std::vector<int>  nodeIDs;//ѡ�����·ID
		int passengerFlow = 0;     //ѡ����·�ĵ�ǰʱ�̿���
		int addcost = 0;           //ѡ����·�Ļر�

		travel(int timeid, std::vector<int>  nodeIDs, int passengerFlow, int addcost) {
			this->timeid        = timeid;
			this->nodeIDs       = nodeIDs;
			this->passengerFlow = passengerFlow;
			this->addcost       = addcost;
		}

		void showTravel() {

			std::cout << "����ʱ�䣺" << this->timeid<<"    ";
			std::cout << "�ؿ�����  " << this->passengerFlow<<"   ";
			std::cout << "�г̴��ۣ�" << this->addcost<<"   ";
			std::cout << ";��վ�㣺";
			for (int i = 0; i < this->nodeIDs.size(); i++) {
				std::cout << this->nodeIDs[i]<<"  ";
			}
			std::cout << std::endl;
		}


	};
   
	
	//����״̬
	class  bus {

	public:

		int   timeBacktoMetro;      //�������س�վʱ��
		bool  busHaveUsed;          //�����Ƿ�ʹ��
		bool  ifFirstOutputDepot;   //�����Ƿ��Ѿ�������
		float costOnBus;            //��ǰ�����ϵĴ���
		bool  hasRoute;             //��ǰ�����Ƿ���ʻ��ĳһ��·��
		int   RouteNum;             //��ǰ������ʻ����·���
		int   routeFlow;            //��ǰ��·�ϵĿ���
		int   totalDistance = 0;    //��������ʻ�����Ŀ
		int   totalWaitTime = 0;    //�����ڳ�����ܵȴ�ʱ��

		std::vector<travel>  travelList; 

		bus() {

			ifFirstOutputDepot = true;
			costOnBus          = 0;
			hasRoute           = false;
			RouteNum           = -1;
			busHaveUsed        = false;
			timeBacktoMetro    = 0;
			routeFlow          = 0;
			totalDistance      = 0;
			totalWaitTime      = 0;
		}
        
		bus(int timeBacktoMetro, bool busHaveUsed, bool ifFirstOutputDepot, float costonbus, bool hasRoute, int RouteNum,int dist,int waitTime) {

			this->timeBacktoMetro    = timeBacktoMetro;
			this->busHaveUsed        = busHaveUsed;
			this->ifFirstOutputDepot = ifFirstOutputDepot;
			this->costOnBus          = costonbus;
			this->hasRoute           = hasRoute;
			this->RouteNum           = RouteNum;
			this->totalDistance      = dist;
			this->totalWaitTime      = waitTime;
		}

		//�����ؿ��������ۺ���
		int flowEvaluate(int  waitNum) {

			float reward = 0;
			MCT::Reward Reward(80, 20);
			reward = Reward(waitNum);
			return reward;
		}
        

		//���ۺ���Ϊ�岿��
		//�Ƿ񷢳�
		//��ʻ���
		//������
		//�����ڳ�վͣ��ʱ��
		//������վ�䳵��Ŀ�ĳͷ�ֵ

		int busAttractiveToRoute(PDPTW::Route route,int routeflow) {

			int attractive = 0;
			//�����Ĵ���
			if (!this->busHaveUsed) {
				attractive -= 83;
			}
			//��ʻ��̵Ĵ���
			//attractive -= (totalDistance / 1000)*2.296;
			//�ȴ�ʱ��Ĵ���
			attractive += flowEvaluate(routeflow);
			return attractive;
		};

		bus & operator=(bus nBus) {

			this->timeBacktoMetro    = nBus.timeBacktoMetro;
			this->busHaveUsed        = nBus.busHaveUsed;
			this->ifFirstOutputDepot = nBus.ifFirstOutputDepot;
			this->costOnBus          = nBus.costOnBus;
			this->hasRoute           = nBus.hasRoute;
			this->RouteNum           = nBus.RouteNum;
			this->routeFlow          = nBus.routeFlow;
			this->totalDistance      = nBus.totalDistance;
			this->totalWaitTime      = nBus.totalWaitTime;
			return *this;
		}

		void showBusTravelList() {

			for (int i = 0; i < this->travelList.size(); i++) {
				this->travelList[i].showTravel();
			}


		}

		~bus() {

		};


	};


	//����
	//����δ�����ĳ�
	//�Լ��Ѿ���·�ϵĳ�


	class BusPot {

	public:
		std::vector<MCT::bus> pot;  //��������
		int  busNum;                //������Ŀ
		int  busInPot;              //�ڳ�վ�ĳ�����Ŀ

		BusPot() {
			this->busNum = 0;         //��ʼ����·�ϳ�����ĿΪ0
			this->busInPot = 0;
		}

		void showCurrBusNum() {
			std::cout << busNum << std::endl;
		}

		//��·ѡ�공�Ժ����³�����Ϣ
		void updateBus(PDPTW::Route route, int BusID ,int cost,int routeflow,int timeID,int dist,int waitTime) {
			
			int   timeBacktoMetro   =timeID*150+route.routeDuration;

			

			bool  busHaveUsed       =1;                       
			bool  ifFirstOutputDepot=false;                    
			float costOnBus         =cost;                    
			bool  hasRoute          =true;                    
			
			travel newTravel(timeID, route.nodeIDs, routeflow, cost);
			
			if (BusID == -1) {

				busNum = busNum + 1;
				MCT::bus newBus(timeBacktoMetro, busHaveUsed, ifFirstOutputDepot, costOnBus, hasRoute, routeflow, dist, waitTime);
				newBus.travelList.push_back(newTravel);
				pot.push_back(newBus);
			}
			else {

				pot[BusID].timeBacktoMetro  = pot[BusID].timeBacktoMetro + route.routeDuration;
				pot[BusID].totalDistance   += dist;
				pot[BusID].totalWaitTime   += waitTime;
				pot[BusID].costOnBus        = pot[BusID].costOnBus + costOnBus;
				pot[BusID].routeFlow        = routeflow;
				pot[BusID].travelList.push_back(newTravel);
			}
		}
        
        //��·ѡ��
		int routeSelectBus(PDPTW::Route route,int routeflow,int timeid) {

			//��ȡ��·������Ϣ
			int BestReward     = 0;
			int duration       = route.routeDuration;
			int dist           = route.routeDistance;
			int singleDuration = route.routeSingleDuration;
			int singleDist     = route.routeSingleDistance;
			int currentReward  = 0;

			//showBusInPot(timeid);
			//std::cout << "duration is: " << duration << "  dist is:  " << dist << "  pot size is:     "<<pot.size()<< std::endl;

			//����һ��δ�����ĳ�ʼ��ʿ
			MCT::bus newBus;
			BestReward = newBus.busAttractiveToRoute(route,routeflow);
			int currentBus  = -1;
			int currWaitTime=  0;
			int bestWaitTime=  0;

			for (int i = 0; i < pot.size(); i++) {
				//std::cout << pot[i].timeBacktoMetro << std::endl;
				if((pot[i].timeBacktoMetro-timeid*150)<=150) {
					 
					currentReward = pot[i].busAttractiveToRoute(route, routeflow);
					currWaitTime  = timeid * 150 - pot[i].timeBacktoMetro;
				
					if (currentReward >= BestReward) {
						BestReward   = currentReward;
						bestWaitTime = currWaitTime;
						currentBus   = i;
					}
				}
			}
			updateBus(route, currentBus, BestReward, routeflow, timeid, dist, bestWaitTime);
			return BestReward;
		}

		//���³���״̬�����ص�ǰʱ�̿��Ե��õĹ�������Ŀ
		bool hasBus(int timeid) {

			bool _hasbus = false;

			for (int i = 0; i < pot.size(); i++) {

				if ((pot[i].timeBacktoMetro - timeid * 150) <= 150) {
					_hasbus = true;
				}
			}
			return _hasbus;
		}

		void showBusInPot(int timeid) {



			int busNum = 0;

			for (int i = 0; i < pot.size(); i++) {

				if ((pot[i].timeBacktoMetro - timeid * 150) <= 150) {
					busNum += 1;
				}
			}
		    
			std::cout << std::endl;
			std::cout << "��վ�ڵĳ�����Ŀ:  " << busNum << std::endl;
			std::cout << std::endl;




		}

		BusPot & operator=(BusPot pot) {

			this->busInPot = pot.busInPot;
			this->busNum = pot.busNum;

			this->pot.clear();

			for (int i = 0; i < pot.pot.size(); i++) {
				this->pot.push_back(pot.pot[i]);
			}
			return *this;
		}

		void showBusTravelList() {

			for (int i = 0; i < this->pot.size(); i++) {

				std::cout << "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------" << std::endl;
				this->pot[i].showBusTravelList();
				std::cout << "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------" << std::endl;
			}


		}

		~BusPot() {

		};
	};



	//MCT���������
	typedef struct action_priors {
		move onemove;
		float prob;

		action_priors() {

			this->onemove.routeSelct_y =-1;
			this->onemove.timeid_x = -1;
			this->prob = -1;
		}

		action_priors(move action, float prob) {

			this->onemove = action;
			this->prob = prob;

		}

		bool operator<(const action_priors & b) const {
			return prob < b.prob;
		}


		bool operator==(const action_priors & b) const {
			return (onemove.routeSelct_y == b.onemove.routeSelct_y) && (onemove.timeid_x == b.onemove.timeid_x);
		}
	};


	//���Ҹ��������������
	//���ݲ�ͬ�Ĳ��Զ����̽�������
	class Agent {

	public:

		Agent() {

		}

		Agent(std::vector<PDPTW::company> companys) {
			this->companys = companys;
		}

		void setcompanys() {
			this->companys = companys;
		}

		//�������̰������
		void  BaseGreedySearch(Board &board, BusPot &pot, const std::map<int, std::vector<int>> companytypeRouteDict, const std::vector<PDPTW::Route> RoutePool,
			bool verbose = false, int currentTimeID = 0, int terminalTimeID = 24) {

			//��ʼ����ǰ��ʱ��ID
			int timeid = currentTimeID;
			//Լ��ÿһ��timeID ���Բ����Ĵ���
			int perTimeidProcessNum = 8;
			int processNum = 0;
			//����ʱ���жϵ�ǰ��Ϸ�Ƿ����

			 

			while (timeid <= terminalTimeID) {

				 
				//��ȡ��ǰʱ�̵�״̬
				std::vector<float>  state = board.getState(timeid);
				std::vector<float>  nextstate = board.getState(timeid + 1);

				//��ȡ���ڵ�ǰ״̬��Ϊ������
				std::vector<bool> busHaveArrived = board.getHasArrived();


				//������·����
				if (verbose == true) {
					std::cout << "action size is: " << busHaveArrived.size() << std::endl;
					for (int i = 0; i < busHaveArrived.size(); i++) {
						if (busHaveArrived[i]) {
							std::cout << i << "   is:   " << busHaveArrived[i] << std::endl;
						}
					}
				}

				std::vector<action_priors> actions = AgentBasePolicy(timeid, state, nextstate, companytypeRouteDict, pot, busHaveArrived);

				//ѡȡ�����������Ϊ
				float maxprob = 0;
				move  action;
				int   selectRouteID = -1;

				for (int i = 0; i < actions.size(); i++) {

					float currprob = actions[i].prob;

					if (currprob > maxprob) {
						maxprob = currprob;
						action.timeid_x = timeid;
						action.routeSelct_y = actions[i].onemove.routeSelct_y;
						selectRouteID = actions[i].onemove.routeSelct_y;
					}
				}

				if (actions.size() == 0) {
					timeid = timeid + 1;
					processNum = 0;
					continue;
				}


				//������·����
				if (verbose == true) {
					std::cout << "action size is: " << actions.size() << std::endl;
					for (int i = 0; i < actions.size(); i++) {
						std::cout << actions[i].prob << std::endl;
						std::cout << actions[i].onemove.routeSelct_y << std::endl;
					}
				}

				float routeDemand = state[selectRouteID];

				//show move
				if (verbose == true) {
					std::cout << "time id is: " << timeid << std::endl;
					std::cout << "select Route ID is: " << selectRouteID << std::endl;
					std::cout << "route Demand is: " << routeDemand << std::endl;
					std::cout << "current time id process times : " << processNum << std::endl;
				}

				//��������
				board.updateBoard(RoutePool, action, 80);

				if (verbose == true) {
					board.showBoard();
				}

				//���³���
				pot.routeSelectBus(RoutePool[selectRouteID], routeDemand, timeid);
				//��ǰ���������ۼ�
				processNum = processNum + 1;
				state = board.getState(23);
				//getGamePlayValue(board, pot, companys, false);

				if (timeid < terminalTimeID) {
					if (board.islineEnd(RoutePool, timeid) || processNum >= perTimeidProcessNum) {
						timeid = timeid + 1;
						processNum = 0;
					}
				}
				else {
					if (board.isGameEnd(RoutePool)) {
						timeid = timeid + 1;
					}
				}
			}
			//board.showBoard();
			std::cout << "��������" << pot.pot.size() << std::endl;
			//��ȡ�ر�
		}

		std::vector<action_priors> AgentBasePolicy(int timeid, std::vector<float> state, std::vector<float> nextstate, std::map<int, std::vector<int>> companytypeRouteDict, BusPot pot, vector<bool> hasArrived) {

			//��Ϊ�б�
			//�����ʽΪ action prior
			std::vector<action_priors> actions;
			//���ȼ�����д�˾
			std::vector<int> largeCompanyRouteIDs = companytypeRouteDict.at(2);
			//��⵱ǰ��˾�Ƿ���Ҫ���з���
			float sum = 0;
			for (int i = 0; i < largeCompanyRouteIDs.size(); i++) {

				int largeCompanyID = largeCompanyRouteIDs[i];
				//std::cout << i << "  " << largeCompanyID << std::endl;
				if (state[largeCompanyID] >= 64) {

					int routeID = i;
					move onemove(timeid, largeCompanyID);
					float prob = state[largeCompanyID];
					sum = sum + prob;
					action_priors action(onemove, prob);
					actions.push_back(action);
				}
			}

			//std::cout << "sum is: " << sum << std::endl;
			//�ж��Ƿ�����Ϊ
			if (actions.size() > 0) {
				//����
				for (int i = 0; i < actions.size(); i++) {
					actions[i].prob = actions[i].prob / sum;
				}
				//����
				return actions;
			}
			//��������й�˾��С��˾
			std::vector<int> middleCompanyRouteIDs = companytypeRouteDict.at(0);
			std::vector<int> smallCompanyRoteIDs = companytypeRouteDict.at(1);
			if (timeid < 24) {
				for (int i = 0; i < middleCompanyRouteIDs.size(); i++) {

					int middleCompanyRouteID = middleCompanyRouteIDs[i];
					if (middleCompanyRouteID == 0) {
						continue;
					}
					move onemove(timeid, middleCompanyRouteID);

					//�Ľ���ķ���
					Reward reward(80, 20);
					float  currentReward = reward(state[middleCompanyRouteID]);
					float  nextReward = reward(nextstate[middleCompanyRouteID]);

					if (currentReward > nextReward) {

						if (state[middleCompanyRouteID] == 0) {
							continue;
						}


						float prob = std::exp(state[middleCompanyRouteID] / 80);
						sum = sum + prob;
						action_priors action(onemove, prob);
						actions.push_back(action);
					}

				}
			}
			else {
				for (int i = 0; i < middleCompanyRouteIDs.size(); i++) {

					int middleCompanyRouteID = middleCompanyRouteIDs[i];

					move onemove(timeid, middleCompanyRouteID);
					float prob = std::exp(state[middleCompanyRouteID] / 80);

					if (state[i] >= 36) {

						sum = sum + prob;
						action_priors action(onemove, prob);
						actions.push_back(action);
					}
				}
			}

			if (actions.size() > 0) {
				//����
				for (int i = 0; i < actions.size(); i++) {
					actions[i].prob = actions[i].prob / sum;
				}
				//����
				return actions;
			}

			sum = 0;
			if (timeid < 24) {

				for (int i = 0; i < smallCompanyRoteIDs.size(); i++) {

					int smallCompanyRoteID = smallCompanyRoteIDs[i];

					int timeDiff = timeid - 12;
					float prob = 0;
					move onemove(timeid, smallCompanyRoteID);
					bool hasbus = pot.hasBus(timeid);

					if ((timeDiff >= 0) && (hasArrived[smallCompanyRoteID] == false) && (hasbus)) {
						prob = std::exp((36 + timeDiff * 5) / 80);
						sum = sum + prob;
						action_priors action(onemove, prob);
						actions.push_back(action);
					}
				}
			}
			else {

				for (int i = 0; i < smallCompanyRoteIDs.size(); i++) {

					int smallCompanyRoteID = smallCompanyRoteIDs[i];

					int timeDiff = timeid - 12;
					float prob = 0;
					move onemove(timeid, smallCompanyRoteID);


					if ((timeDiff >= 0) && (hasArrived[smallCompanyRoteID] == false)) {
						prob = std::exp((36 + timeDiff * 5) / 80);
						sum = sum + prob;
						action_priors action(onemove, prob);
						actions.push_back(action);
					}
				}
			}
			for (int i = 0; i < actions.size(); i++) {
				actions[i].prob = actions[i].prob / sum;
			}
			return actions;
		}

		float getGamePlayValue(Board &board, BusPot &buspot, bool verbose = false) {

			float leafvalue = 0;

			//��⳵��ĳ�����Ŀ
			int busNum = 0;
			busNum = buspot.pot.size();

			
			//��⳵����ÿ������״��
			float totalcostonbus = 0;
			for (int i = 0; i < buspot.pot.size(); i++) {
				totalcostonbus += buspot.pot[i].costOnBus;
				totalcostonbus -= (buspot.pot[i].totalDistance / 1000)*2.296/10;
				totalcostonbus -= (buspot.pot[i].totalWaitTime/60)*3;
			}

			//�������վ���ʣ���û����
			std::vector<int> stationWaitFlow = board.getStationWaitFlow();

			float restflowcost = 0;
			for (int i = 0; i < stationWaitFlow.size(); i++) {
				restflowcost = restflowcost + stationWaitFlow[i];
			}

			//Ҷ�ӽڵ��ֵ�켣
			leafvalue = totalcostonbus - restflowcost*2;


			if (verbose == true) {
				//��ʾҶ�ӽڵ�ļ�ֵ
				std::cout << "Ҷ�Ӽ�ֵ�ǣ� " << leafvalue << std::endl;
			}


			return leafvalue;
		}

		~Agent() {


		}

	private:
		std::string policyType = "greedy"; // agentʹ�õĲ���Ĭ����̰��
		std::vector<PDPTW::company> companys;
	};
	

	//���ؿ������ڵ�
	struct selectAction {

		move action;
		class mctTreeNode*  node;

		selectAction(move act, mctTreeNode* oneNode) {
			action = act;
			node = oneNode;
		}
	};

	class mctTreeNode {

	public:

		mctTreeNode(mctTreeNode * parent,float prior_p){
			this->parent = parent;
			this->p = prior_p;

		};

        
		selectAction select(float c_puct) {

			float max_prob = -999999;
			std::map<move, mctTreeNode*>::iterator iter;
			 

			move currmove(0,0);
			mctTreeNode * treenode;

			for (iter = children.begin();iter!= children.end();iter++) {

				float value = iter->second->get_value(c_puct);

				if (value > max_prob) {

					max_prob = value;

					currmove.routeSelct_y = iter->first.routeSelct_y;
					currmove.timeid_x = iter->first.timeid_x;

					treenode = iter->second;
				}
			}
			return selectAction(currmove, treenode);
		}

		void expand(std::vector<action_priors> actions) {
			
			 



			for (int i = 0; i < actions.size(); i++) {
				move  action = actions[i].onemove;
				float prob = actions[i].prob;
				
				std::map<move, mctTreeNode*>::iterator iter;
				bool isfind = false;

				for(iter=this->children.begin();iter!=this->children.end();iter++)
				{   

					if (iter->first == action) {
						isfind = true;
					}
				}


				if (!isfind) {
					std::cout << "expand" << std::endl;
					mctTreeNode* child = new mctTreeNode(this, prob);
					children.insert(std::pair<move, mctTreeNode*>(action, child));
				}

			}
		}
        
		float get_value(float c_puct) {
			this->u = (c_puct*this->p)*sqrt(this->parent->n_visit) / (1 + this->n_visit);
			this->Q = this->Q + this->u;

			return this->Q;
		}

		void update(float leaf_value) {
			this->n_visit += 1;
			this->Q += 1.0*(leaf_value - this->Q) / this->n_visit;
		}

		void update_recursive(float leaf_value) {

			if (this->parent != NULL) {
				this->parent->update_recursive(leaf_value);
			}

			this->update(leaf_value);
		}

		//��������һ��Ҷ�ڵ�ʹ�õ�ǰ�Ĳ��Խ���չ��
		void rollout(Board &board, BusPot &pot, std::map<int, std::vector<int>> companytypeRouteDict, const std::vector<PDPTW::Route> RoutePool,int currentTimeID,int terminalTimeID) {
			agent.BaseGreedySearch(board, pot, companytypeRouteDict, RoutePool,currentTimeID,terminalTimeID);
		}



		bool is_leaf() {
			return children.size() == 0;
		}

		bool is_root() {
			return parent == NULL;
		}

		~mctTreeNode() {
			
		};
		
		mctTreeNode*  parent; //���ڵ�
		std::map<move, mctTreeNode*> children;//�ӽڵ�
		int    n_visit = 0;   //�ڵ���ʴ���
		float  Q = 0;       
		float  u = 0;
		float  p = 0;
		Agent  agent;
	};




	//MCT ��Ҫ����
	class mct {

	public:
		mct() {
			root = new mctTreeNode(NULL, 0);
			nums = 5000;
		}

		mct(int num, std::map<int, std::vector<int>> companytypeRouteDict,std::vector<PDPTW::Route> RoutePool,Board board) {
			
			root = new mctTreeNode(NULL, 0);
			nums = num;
			this->companytypeRouteDict = companytypeRouteDict;
			for (int i = 0; i < RoutePool.size(); i++) {
				this->routePool.push_back(RoutePool[i]);
			}
			this->board = board;
			//std::cout << this->board.getBoardTable() << std::endl;
		}

		void getinitialValue(bool verbose = false, int currentTimeID = 0, int terminalTimeID = 24) {
			BusPot pot;
			Board  aboard = this->board;
			agent.BaseGreedySearch(aboard, pot, companytypeRouteDict, routePool, false);
			float value = agent.getGamePlayValue(aboard, pot,true);
			std::cout << "��ʼֵ�ǣ� " << value << std::endl;
			bestValue = value;
		}


		void gameSet() {

			//10% times is used to random search

			int randomSearchTimes = 0.1 * nums;
			int greedySearchTimes = 0.9 * nums;
           

			//̰������
			for (int i = 0; i < greedySearchTimes; i++) {
				std::cout << "��Ϸ������ " << i << std::endl;
				oneGame(24, this->bestValue, 1);
			}

			bestBoard.showBoard();
			std::cout <<"�䳵��Ŀ"<< BestPot.busNum << std::endl;
			BestPot.showBusTravelList();
		}

		//һ����Ϸ
		void oneGame(int terminalTimeID,float currentBestValue,float c_puct) {

			 

			//assert(board.getBoardTable().rows() <= terminalTimeID);

			int timeid = 0;
			Board newBoard  = this->board;
			BusPot newPot;

			mctTreeNode * node = this->root;

			//��ʼ��Ϸ

			int processTimes = 0;
			while (timeid < terminalTimeID) {
				
				std::cout << timeid << std::endl;

				if (node->is_leaf()) {
					break;
				}
				selectAction action_node = node->select(c_puct);

				//��ȡ��һ�����ڵ�
				node   = action_node.node;

				//��ȡ��һ�����ڵ����ڵ�ʱ��
				timeid = action_node.action.timeid_x;

				//��ȡ��Ϊѡ�����·ID
				int selectRouteID = action_node.action.routeSelct_y;

				if (selectRouteID == -1) {
					continue;
				}

				
				//��ȡѡ����·���Ŷ�����
				std::vector<float>  state = newBoard.getState(timeid);
				float routeDemand = state[selectRouteID];
				
				//��������
				newBoard.updateBoard(this->routePool, action_node.action, 80);

				//���³���
				newPot.routeSelectBus(routePool[selectRouteID], routeDemand, timeid);
				 
			}

			//��ȡ��ǰʱ�̵�״̬
			
			std::vector<float>  state = newBoard.getState(timeid);
			std::vector<float>  nextstate = newBoard.getState(timeid + 1);
			
			//��ȡ���ڵ�ǰ״̬��Ϊ������
			std::vector<bool>   busHaveArrived = newBoard.getHasArrived();
			
			
			std::vector<action_priors> actions;
			if (newBoard.islineEnd(routePool,timeid)) {
					float prob = 1;
					move  action(timeid + 1, -1);
					action_priors one_action;
					one_action.onemove = action;
					one_action.prob = prob;
					actions.push_back(one_action);
			}
			else {
				//��ȡ״̬�����Ե�ǰ״̬������
				actions = this->agent.AgentBasePolicy(timeid, state, nextstate, companytypeRouteDict, newPot, busHaveArrived);
				std::cout << "��ѡ��Ϊ����: " << actions.size() << std::endl;

				if (actions.size() == 0) {
					float prob = 1;
					move  action(timeid + 1, -1);
					action_priors one_action;
					one_action.onemove = action;
					one_action.prob = prob;
					actions.push_back(one_action);
				}

			}
			node->expand(actions);
			//������ǰ״̬�ļ�ֵ�û�
			float leafvalue = 0;
			std::cout << "timeid is: " << timeid << std::endl;
			std::cout << "terminaltimeid is: " << terminalTimeID << std::endl;
			agent.BaseGreedySearch(newBoard, newPot, companytypeRouteDict, routePool,false,timeid, terminalTimeID);
			leafvalue = agent.getGamePlayValue(newBoard, newPot);
			std::cout << "��ǰ��Ҷ��ֵ��: " << leafvalue << std::endl;
			std::cout << "time id is: "<<timeid << std::endl;
			//std::cout << newBoard.getBoardTable() << std::endl;
		 

			float reward = 0;
			//���Ҷ�ӽڵ��ֵ�ȵ�ǰ���ֵ��
			if (leafvalue > bestValue) {
				reward    = (leafvalue - bestValue) / 10 + 10;
				bestValue = leafvalue;
				bestBoard = newBoard;
				BestPot   = newPot;				
			}
			else if (leafvalue > 1.2*bestValue) {
				reward = (leafvalue - bestValue) /10;

			}
			//���Ҷ�ӽڵ��ֵ�ȵ�ǰ���ֵ��
			else{
				reward = (leafvalue - bestValue) / 10;
			}
			//����
			node->update_recursive(reward);
			std::cout << "��ǰ��ѵ�Ҷ��ֵ��: " << bestValue << std::endl;
		}
        
		~mct() {

		}

	private:

		mctTreeNode * root;
		Agent  agent;
		int    nums = 0;
		Board  board;
		std::vector<PDPTW::Route> routePool;
		std::map<int, std::vector<int>> companytypeRouteDict;
		float  bestValue = 0;
		Board  bestBoard = this->board;
		BusPot BestPot;
	};
	



}