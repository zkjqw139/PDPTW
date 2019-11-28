#pragma once
#include<iostream>
#include<stdio.h>
#include<vector>
#include<Eigen/Dense>
#include"Route.cuh"
#include<map>
#include<math.h>

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

		Board(Eigen::MatrixXd  boardTable,std::vector<int> totalStationWaitFlow) {
			this->boardTable = boardTable;

			for (int i = 0; i < boardTable.rows(); i++) {
				this->hasBusArrived.push_back(false);
			}

			
			this->totalStationWaitFlow = totalStationWaitFlow;


		};

		void showBoard() {
			std::cout << this->boardTable << std::endl;
		}

		Eigen::MatrixXd getBoardTable() {
			return this->boardTable;
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
		void updateBoard(std::vector<PDPTW::Route> RoutePool,move onemove,int busLoadLimit) {

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
				
				for (int i = 0; i > nodeIDs.size(); i++) {
					int id = nodeIDs[i];
					this->totalStationWaitFlow[id] -= percent.at(id)*getDemand;
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

		~Board() {
		
		};

	private:
		Eigen::MatrixXd   boardTable;
		std::vector<bool> hasBusArrived;
		std::vector<bool> stationHasArrived;  
		std::vector<int>  totalStationWaitFlow;
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

		bus() {

			ifFirstOutputDepot = true;
			costOnBus          = 0;
			hasRoute           = false;
			RouteNum           = -1;
			busHaveUsed        = false;
			timeBacktoMetro    = 0;
			routeFlow          = 0;
		}


		bus(int tineBacktoMetro, bool busHaveUsed, bool ifFirstOutputDepot, float costonbus, bool hasRoute, int RouteNum) {

			this->timeBacktoMetro = timeBacktoMetro;
			this->busHaveUsed = busHaveUsed;
			this->ifFirstOutputDepot = ifFirstOutputDepot;
			this->costOnBus = costOnBus;
			this->hasRoute = hasRoute;
			this->RouteNum = RouteNum;
		}

		//�����ؿ��������ۺ���
		int flowEvaluate(int  waitNum) {

			int reward = 0;

			if (waitNum <= 36) {

				reward = waitNum;
			}
			else if (waitNum > 36 && waitNum <= 64) {
				reward = (waitNum - 36) * 2 + 36;
			}
			else if (waitNum > 64 && waitNum <= 80) {

				reward = 92;
			}
			else if (waitNum > 80) {
				reward = reward - 4.6*(waitNum - 80);
			}
			return reward;
		}
        
	    

		int busAttractiveToRoute(PDPTW::Route route,int routeflow) {

			int attractive = 0;
			if (!this->busHaveUsed) {
				attractive -= 83;
			}
			attractive += flowEvaluate(routeflow);
			return attractive;
		};


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


		BusPot() {
			int busnum = 0;         //��ʼ����·�ϳ�����ĿΪ0
		}

		void showCurrBusNum() {
			std::cout << busNum << std::endl;
		}

		//��·ѡ�공�Ժ����³�����Ϣ
		void updateBus(PDPTW::Route route, int BusID ,int cost,int routeflow,int timeID) {
			
			int   timeBacktoMetro   = timeID*150+route.routeDuration;
			bool  busHaveUsed       =1;                       
			bool  ifFirstOutputDepot=false;                    
			float costOnBus         =cost;                    
			bool  hasRoute          =true;                    
		 
			if (BusID == -1) {
				busNum = busNum + 1;
				MCT::bus newBus(timeBacktoMetro, busHaveUsed, ifFirstOutputDepot, costOnBus, hasRoute, routeflow);
				pot.push_back(newBus);
			}
			else {
				pot[BusID].timeBacktoMetro = pot[BusID].timeBacktoMetro + route.routeDuration;
				pot[BusID].costOnBus = pot[BusID].costOnBus + costOnBus;
				pot[BusID].routeFlow = routeflow;
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

			//����һ��δ�����ĳ�ʼ��ʿ
			MCT::bus newBus;
			BestReward = newBus.busAttractiveToRoute(route,routeflow);
			int currentBus = -1;

			for (int i = 0; i < pot.size(); i++) {

				if(abs(pot[i].timeBacktoMetro-timeid*150)<=150) {
					currentReward = pot[i].busAttractiveToRoute(route, routeflow);
					if (currentReward > BestReward) {
						BestReward = currentReward;
						currentBus = i;
					}
				}
			}
			updateBus(route, currentBus, BestReward, routeflow, timeid);
			return BestReward;
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


	
	class mctTreeNode {

	public:

		mctTreeNode(mctTreeNode * parent,float prior_p){
			this->parent = parent;
			this->p = prior_p;
		};
		
		std::pair<move,mctTreeNode*> select(float c_puct) {

			float max_prob = -999999;
			std::map<move, mctTreeNode*>::iterator iter;
			iter = children.begin();

			move currmove(0,0);
			mctTreeNode * treenode;

			while (iter != children.end()) {

				float value = iter->second->get_value(c_puct);

				if (value > max_prob) {

					max_prob = value;

					currmove.routeSelct_y = iter->first.routeSelct_y;
					currmove.timeid_x = iter->first.timeid_x;

					treenode = iter->second;
				}
			}
			return std::pair<move, mctTreeNode*>(currmove, treenode);
		}

		void expand(std::vector<action_priors> actions) {
			
			for (int i = 0; i < actions.size(); i++) {
				move  action = actions[i].onemove;
				float prob = actions[i].prob;
				
				if (this->children.count(action)){
					mctTreeNode* child = new mctTreeNode(this, prob);
					children.insert(std::pair<move, mctTreeNode*>(action, child));
				}
			}
		}
        
		float get_value(float c_puct) {
			this->u = (c_puct*this->p)*sqrt(this->parent->n_visit) / (1 + this->n_visit);
			this->Q = this->Q + this->u;
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
	};


	//���Ҹ��������������
	//���ݲ�ͬ�Ĳ��Զ����̽�������
	class Agent {

	public:
		Agent() {


		}

		//�������̰������
		void  BaseGreedySearch(Board &board,BusPot &pot, std::map<int, std::vector<int>> companytypeRouteDict, std::vector<PDPTW::Route> RoutePool,bool verbose=false) {

			//��ʼ����ǰ��ʱ��ID
			int timeid = 0;
			//Լ��ÿһ��timeID ���Բ����Ĵ���
			int perTimeidProcessNum = 8;
			int processNum = 0;
			//����ʱ���жϵ�ǰ��Ϸ�Ƿ����
			while (timeid <= 24) {

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
							std::cout <<i<<"   is:   "<< busHaveArrived[i] << std::endl;
						}
					}
				}

				std::vector<action_priors> actions = AgentBasePolicy(timeid, state, nextstate, companytypeRouteDict,  pot, busHaveArrived);

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
					std::cout <<"action size is: "<< actions.size()<<std::endl;
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
				pot.routeSelectBus(RoutePool[selectRouteID],routeDemand,timeid);
				if (verbose == true) {




				}
				//��ǰ���������ۼ�
				processNum = processNum + 1;


				if (timeid < 24) {
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

			//��ȡ�ر�
		}

		std::vector<action_priors> AgentBasePolicy(int timeid,std::vector<float> state, std::vector<float> nextstate,std::map<int, std::vector<int>> companytypeRouteDict, BusPot pot,vector<bool> hasArrived) {

			//��Ϊ�б�
			//�����ʽΪ action prior
			std::vector<action_priors> actions;
            //���ȼ�����д�˾
			std::vector<int> largeCompanyRouteIDs = companytypeRouteDict.at(2);
			//��⵱ǰ��˾�Ƿ���Ҫ���з���
			float sum = 0;
			for (int i = 0; i < largeCompanyRouteIDs.size(); i++) {

				int largeCompanyID = largeCompanyRouteIDs[i];
				std::cout << i << "  " << largeCompanyID << std::endl;
				if (state[largeCompanyID] >= 64) {

					int routeID = i;
					move onemove(timeid, largeCompanyID);
					float prob = state[largeCompanyID];
					sum = sum + prob;
					action_priors action(onemove, prob);
					actions.push_back(action);
				}
			}
			 
			
			std::cout << "sum is: " << sum << std::endl;
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
			std::vector<int> smallCompanyRoteIDs   = companytypeRouteDict.at(1);
			if (timeid < 24) {
				for (int i = 0; i < middleCompanyRouteIDs.size(); i++) {

					int middleCompanyRouteID = middleCompanyRouteIDs[i];

					move onemove(timeid, middleCompanyRouteID);
					float prob = std::exp(state[middleCompanyRouteID]/80);

					if (nextstate[i] >= 80) {

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
					float prob = std::exp(state[middleCompanyRouteID]/80);

					if (state[i] >= 36) {

						sum = sum + prob;
						action_priors action(onemove, prob);
						actions.push_back(action);
					}
				}
			}
				
			for (int i = 0; i < smallCompanyRoteIDs.size(); i++) {

				int smallCompanyRoteID = smallCompanyRoteIDs[i];

				int timeDiff = timeid - 12;
				float prob   = 0;
				move onemove(timeid, smallCompanyRoteID);

				
				if ( (timeDiff >= 0) && (hasArrived[smallCompanyRoteID]==false)) {

					 

					prob = std::exp((36 + timeDiff * 5)/80);
					sum = sum + prob;
					action_priors action(onemove, prob);
					actions.push_back(action);
				}
			}

			//����
			std::cout << "action size is: " << actions.size() << std::endl;
			std::cout << "sum is: " << sum << std::endl;

			for (int i = 0; i < actions.size(); i++) {
					actions[i].prob = actions[i].prob / sum;
			}
			//����
			return actions;
		}

		~Agent() {


		}

	private:
		std::string policyType = "greedy"; // agentʹ�õĲ���Ĭ����̰��
	};


	


}