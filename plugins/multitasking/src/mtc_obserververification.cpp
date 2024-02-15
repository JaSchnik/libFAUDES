/** @file mtc_obserververification.cpp 

Methods to verify the obsrver condition for natural projections.
The observer condition is, e.g., defined in 
K. C. Wong and W. M. Wonham, “Hierarchical control of discrete-event
systems,” Discrete Event Dynamic Systems: Theory and Applications, 1996.
In addition, methods to verify output control consistency (OCC) and 
local control consistency (LCC) are provided. See for example
K. Schmidt and C. Breindl, "On Maximal Permissiveness of Hierarchical and Modular Supervisory
Control Approaches for Discrete Event Systems," Workshop on Discrete Event Systems, 2008. 
*/

/* FAU Discrete Event Systems Library (libfaudes)

   Copyright (C) 2006  Bernd Opitz
   Exclusive copyright is granted to Klaus Schmidt

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA */

#include "mtc_obserververification.h"
#include "mtc_observercomputation.h"
#include "corefaudes.h"


namespace faudes {

bool IsMtcObs(const MtcSystem& rLowGen, const EventSet& rHighAlph){
	OP_DF("IsMtcObs(" << rLowGen.Name() << "," << rHighAlph.Name() << ")");
	// Initialization of variables
	EventSet newHighAlph = rHighAlph;
	EventSet controllableEvents;
	std::map<Transition,Idx> mapChangedTrans;
	Generator genDyn(rLowGen);
	std::map<Transition,Transition> mapChangedTransReverse;
	std::map<Idx,Idx> mapStateToPartition;
	std::map<Idx, EventSet> mapRelabeledEvents;
	bool observer;
	// One step of the observer algorithm: A dynamic system is computed that fulfills the one-step observer condition. 
	// if the result is equal to the original generator, then the natural projection on the high-level alphabet fulfills the observer property
	calculateDynamicSystemObs(rLowGen, newHighAlph, genDyn);
	Generator genPart;
	// compute coarsest quasi-congruence on the dynamic system
	ComputeBisimulation(genDyn, mapStateToPartition, genPart);
	// check if quotient automaton is deterministic and free of unobservable events
	// and relabel transitions in rLowGen if necessary. The high-level alphabet is modified accordingly
	Generator genObs(rLowGen);
	observer=relabel(genObs, controllableEvents, newHighAlph, mapStateToPartition, mapChangedTransReverse,  mapChangedTrans, mapRelabeledEvents);
	// return the result of the relabeling 
	return observer;

}


}// namespace faudes
