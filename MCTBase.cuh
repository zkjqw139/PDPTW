#pragma once
#include<iostream>
#include<stdio.h>
#include<vector>
#include<Eigen/Dense>
#include"Route.cuh"
#include<map>
#include<math.h>
#include"util.cuh"

//MCT 基本数据结构
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


	//客流棋盘
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

		//更新棋盘
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


		//判断当前时刻是否决策结束
		//小公司只会在8：30-8：50决定是否发车
		//大公司的公交线路只会在线路大于24人时考虑发车
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
        
		//判断棋盘游戏是否结束
		//在8：50分判断是否大公司的拼线线路的等待人数都小于20
		//并且判断小公司都已经有车发车
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

		//版面状况
		//对于版面状况来说

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


	

	//车辆行车链记录
	struct  travel{

		int timeid  = 0;           //发车时刻
		std::vector<int>  nodeIDs;//选择的线路ID
		int passengerFlow = 0;     //选择线路的当前时刻客流
		int addcost = 0;           //选择线路的回报

		travel(int timeid, std::vector<int>  nodeIDs, int passengerFlow, int addcost) {
			this->timeid        = timeid;
			this->nodeIDs       = nodeIDs;
			this->passengerFlow = passengerFlow;
			this->addcost       = addcost;
		}

		void showTravel() {

			std::cout << "发车时间：" << this->timeid<<"    ";
			std::cout << "载客量：  " << this->passengerFlow<<"   ";
			std::cout << "行程代价：" << this->addcost<<"   ";
			std::cout << "途径站点：";
			for (int i = 0; i < this->nodeIDs.size(); i++) {
				std::cout << this->nodeIDs[i]<<"  ";
			}
			std::cout << std::endl;
		}


	};
   
	
	//车的状态
	class  bus {

	public:

		int   timeBacktoMetro;      //车辆返回场站时间
		bool  busHaveUsed;          //车辆是否被使用
		bool  ifFirstOutputDepot;   //车辆是否已经发过车
		float costOnBus;            //当前车辆上的代价
		bool  hasRoute;             //当前车俩是否行驶在某一条路上
		int   RouteNum;             //当前车辆行驶的线路编号
		int   routeFlow;            //当前线路上的客流
		int   totalDistance = 0;    //车辆总行驶里程数目
		int   totalWaitTime = 0;    //车辆在车库的总等待时间

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

		//对于载客量的评价函数
		int flowEvaluate(int  waitNum) {

			float reward = 0;
			MCT::Reward Reward(80, 20);
			reward = Reward(waitNum);
			return reward;
		}
        

		//代价函数为五部分
		//是否发车
		//行驶里程
		//满载率
		//车辆在场站停留时间
		//超过场站配车数目的惩罚值

		int busAttractiveToRoute(PDPTW::Route route,int routeflow) {

			int attractive = 0;
			//发车的代价
			if (!this->busHaveUsed) {
				attractive -= 83;
			}
			//行驶里程的代价
			//attractive -= (totalDistance / 1000)*2.296;
			//等待时间的代价
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


	//车库
	//包含未发出的车
	//以及已经在路上的车


	class BusPot {

	public:
		std::vector<MCT::bus> pot;  //车辆管理
		int  busNum;                //车辆数目
		int  busInPot;              //在场站的车辆数目

		BusPot() {
			this->busNum = 0;         //初始化线路上车的数目为0
			this->busInPot = 0;
		}

		void showCurrBusNum() {
			std::cout << busNum << std::endl;
		}

		//线路选完车以后会更新车辆信息
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
        
        //线路选择车
		int routeSelectBus(PDPTW::Route route,int routeflow,int timeid) {

			//获取线路基本信息
			int BestReward     = 0;
			int duration       = route.routeDuration;
			int dist           = route.routeDistance;
			int singleDuration = route.routeSingleDuration;
			int singleDist     = route.routeSingleDistance;
			int currentReward  = 0;

			//showBusInPot(timeid);
			//std::cout << "duration is: " << duration << "  dist is:  " << dist << "  pot size is:     "<<pot.size()<< std::endl;

			//创建一辆未发车的初始巴士
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

		//更新车库状态，返回当前时刻可以调用的公交车数目
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
			std::cout << "场站内的车辆数目:  " << busNum << std::endl;
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



	//MCT搜索树结点
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


	//智囊负责管理搜索过程
	//操纵不同的策略对棋盘进行收索
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

		//最基础的贪婪搜索
		void  BaseGreedySearch(Board &board, BusPot &pot, const std::map<int, std::vector<int>> companytypeRouteDict, const std::vector<PDPTW::Route> RoutePool,
			bool verbose = false, int currentTimeID = 0, int terminalTimeID = 24) {

			//初始化当前的时间ID
			int timeid = currentTimeID;
			//约束每一个timeID 可以操作的次数
			int perTimeidProcessNum = 8;
			int processNum = 0;
			//基于时间判断当前游戏是否结束

			 

			while (timeid <= terminalTimeID) {

				 
				//获取当前时刻的状态
				std::vector<float>  state = board.getState(timeid);
				std::vector<float>  nextstate = board.getState(timeid + 1);

				//获取对于当前状态行为的期望
				std::vector<bool> busHaveArrived = board.getHasArrived();


				//更新线路客流
				if (verbose == true) {
					std::cout << "action size is: " << busHaveArrived.size() << std::endl;
					for (int i = 0; i < busHaveArrived.size(); i++) {
						if (busHaveArrived[i]) {
							std::cout << i << "   is:   " << busHaveArrived[i] << std::endl;
						}
					}
				}

				std::vector<action_priors> actions = AgentBasePolicy(timeid, state, nextstate, companytypeRouteDict, pot, busHaveArrived);

				//选取最大期望的行为
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


				//更新线路客流
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

				//更新棋盘
				board.updateBoard(RoutePool, action, 80);

				if (verbose == true) {
					board.showBoard();
				}

				//更新车库
				pot.routeSelectBus(RoutePool[selectRouteID], routeDemand, timeid);
				//当前发车次数累加
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
			std::cout << "发车数量" << pot.pot.size() << std::endl;
			//获取回报
		}

		std::vector<action_priors> AgentBasePolicy(int timeid, std::vector<float> state, std::vector<float> nextstate, std::map<int, std::vector<int>> companytypeRouteDict, BusPot pot, vector<bool> hasArrived) {

			//行为列表
			//输出格式为 action prior
			std::vector<action_priors> actions;
			//首先检测所有大公司
			std::vector<int> largeCompanyRouteIDs = companytypeRouteDict.at(2);
			//检测当前大公司是否需要迫切发车
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
			//判断是否有行为
			if (actions.size() > 0) {
				//正则化
				for (int i = 0; i < actions.size(); i++) {
					actions[i].prob = actions[i].prob / sum;
				}
				//返回
				return actions;
			}
			//检测所有中公司和小公司
			std::vector<int> middleCompanyRouteIDs = companytypeRouteDict.at(0);
			std::vector<int> smallCompanyRoteIDs = companytypeRouteDict.at(1);
			if (timeid < 24) {
				for (int i = 0; i < middleCompanyRouteIDs.size(); i++) {

					int middleCompanyRouteID = middleCompanyRouteIDs[i];
					if (middleCompanyRouteID == 0) {
						continue;
					}
					move onemove(timeid, middleCompanyRouteID);

					//改进后的方案
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
				//正则化
				for (int i = 0; i < actions.size(); i++) {
					actions[i].prob = actions[i].prob / sum;
				}
				//返回
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

			//检测车库的车辆数目
			int busNum = 0;
			busNum = buspot.pot.size();

			
			//检测车库里每辆车的状况
			float totalcostonbus = 0;
			for (int i = 0; i < buspot.pot.size(); i++) {
				totalcostonbus += buspot.pot[i].costOnBus;
				totalcostonbus -= (buspot.pot[i].totalDistance / 1000)*2.296/10;
				totalcostonbus -= (buspot.pot[i].totalWaitTime/60)*3;
			}

			//检测所有站点的剩余用户情况
			std::vector<int> stationWaitFlow = board.getStationWaitFlow();

			float restflowcost = 0;
			for (int i = 0; i < stationWaitFlow.size(); i++) {
				restflowcost = restflowcost + stationWaitFlow[i];
			}

			//叶子节点价值轨迹
			leafvalue = totalcostonbus - restflowcost*2;


			if (verbose == true) {
				//显示叶子节点的价值
				std::cout << "叶子价值是： " << leafvalue << std::endl;
			}


			return leafvalue;
		}

		~Agent() {


		}

	private:
		std::string policyType = "greedy"; // agent使用的策略默认是贪婪
		std::vector<PDPTW::company> companys;
	};
	

	//蒙特卡洛树节点
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

		//对于任意一个叶节点使用当前的策略进行展开
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
		
		mctTreeNode*  parent; //父节点
		std::map<move, mctTreeNode*> children;//子节点
		int    n_visit = 0;   //节点访问次数
		float  Q = 0;       
		float  u = 0;
		float  p = 0;
		Agent  agent;
	};




	//MCT 主要流程
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
			std::cout << "初始值是： " << value << std::endl;
			bestValue = value;
		}


		void gameSet() {

			//10% times is used to random search

			int randomSearchTimes = 0.1 * nums;
			int greedySearchTimes = 0.9 * nums;
           

			//贪婪搜索
			for (int i = 0; i < greedySearchTimes; i++) {
				std::cout << "游戏次数： " << i << std::endl;
				oneGame(24, this->bestValue, 1);
			}

			bestBoard.showBoard();
			std::cout <<"配车数目"<< BestPot.busNum << std::endl;
			BestPot.showBusTravelList();
		}

		//一局游戏
		void oneGame(int terminalTimeID,float currentBestValue,float c_puct) {

			 

			//assert(board.getBoardTable().rows() <= terminalTimeID);

			int timeid = 0;
			Board newBoard  = this->board;
			BusPot newPot;

			mctTreeNode * node = this->root;

			//开始游戏

			int processTimes = 0;
			while (timeid < terminalTimeID) {
				
				std::cout << timeid << std::endl;

				if (node->is_leaf()) {
					break;
				}
				selectAction action_node = node->select(c_puct);

				//获取下一个树节点
				node   = action_node.node;

				//获取下一个树节点所在的时刻
				timeid = action_node.action.timeid_x;

				//获取行为选择的线路ID
				int selectRouteID = action_node.action.routeSelct_y;

				if (selectRouteID == -1) {
					continue;
				}

				
				//获取选择线路的排队人数
				std::vector<float>  state = newBoard.getState(timeid);
				float routeDemand = state[selectRouteID];
				
				//更新棋盘
				newBoard.updateBoard(this->routePool, action_node.action, 80);

				//更新车库
				newPot.routeSelectBus(routePool[selectRouteID], routeDemand, timeid);
				 
			}

			//获取当前时刻的状态
			
			std::vector<float>  state = newBoard.getState(timeid);
			std::vector<float>  nextstate = newBoard.getState(timeid + 1);
			
			//获取对于当前状态行为的期望
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
				//获取状态函数对当前状态的评估
				actions = this->agent.AgentBasePolicy(timeid, state, nextstate, companytypeRouteDict, newPot, busHaveArrived);
				std::cout << "候选行为个数: " << actions.size() << std::endl;

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
			//评估当前状态的价值好坏
			float leafvalue = 0;
			std::cout << "timeid is: " << timeid << std::endl;
			std::cout << "terminaltimeid is: " << terminalTimeID << std::endl;
			agent.BaseGreedySearch(newBoard, newPot, companytypeRouteDict, routePool,false,timeid, terminalTimeID);
			leafvalue = agent.getGamePlayValue(newBoard, newPot);
			std::cout << "当前的叶子值是: " << leafvalue << std::endl;
			std::cout << "time id is: "<<timeid << std::endl;
			//std::cout << newBoard.getBoardTable() << std::endl;
		 

			float reward = 0;
			//如果叶子节点的值比当前最佳值好
			if (leafvalue > bestValue) {
				reward    = (leafvalue - bestValue) / 10 + 10;
				bestValue = leafvalue;
				bestBoard = newBoard;
				BestPot   = newPot;				
			}
			else if (leafvalue > 1.2*bestValue) {
				reward = (leafvalue - bestValue) /10;

			}
			//如果叶子节点的值比当前最佳值差
			else{
				reward = (leafvalue - bestValue) / 10;
			}
			//更新
			node->update_recursive(reward);
			std::cout << "当前最佳的叶子值是: " << bestValue << std::endl;
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