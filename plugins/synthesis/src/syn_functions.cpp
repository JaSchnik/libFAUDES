/** @file syn_functions.cpp Misc functions related to synthesis */

/* FAU Discrete Event Systems Library (libfaudes)

   Copyright (C) 2010 Thomas Moor

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


//#define FAUDES_DEBUG_FUNCTION
   
#include "syn_functions.h"


namespace faudes {




/*
***************************************************************************************
***************************************************************************************
 Implementation
***************************************************************************************
***************************************************************************************
*/



//IsRelativelyMarked(rGenPlant,rGenCand)
bool IsRelativelyMarked(const Generator& rGenPlant, const Generator& rGenCand) {

  // alphabets must match
  if ( rGenPlant.Alphabet() != rGenCand.Alphabet()) {
    std::stringstream errstr;
    errstr << "Alphabets of generators do not match.";
    throw Exception("IsRelativelyMarked", errstr.str(), 100);
  }

#ifdef FAUDES_CHECKED
  // generators are meant to be nonblocking
  if ( !IsNonblocking(rGenCand) ||  !IsNonblocking(rGenPlant)) {
    std::stringstream errstr;
    errstr << "Arguments are expected to be nonblocking.";
    throw Exception("IsRelativelyMarked", errstr.str(), 201);
  }
#endif

#ifdef FAUDES_CHECKED
  // generators are meant to be deterministic
  if ( !IsDeterministic(rGenCand) ||  !IsDeterministic(rGenPlant)) {
    std::stringstream errstr;
    errstr << "Arguments are expected to be deterministic.";
    throw Exception("IsRelativelyMarked", errstr.str(), 202);
  }
#endif

  // perform composition
  std::map< std::pair<Idx,Idx> , Idx> revmap;
  Generator product;
  product.StateNamesEnabled(false);
  Product(rGenPlant,rGenCand,revmap,product);

  // test all reachable states
  std::map< std::pair<Idx,Idx> , Idx>::iterator rit;
  for(rit=revmap.begin(); rit!=revmap.end(); ++rit) {
    // ok: not GPlant-marked state is not considered
    if(!rGenPlant.ExistsMarkedState(rit->first.first)) 
      continue;
    // ok: GPlant-marked state also has GCand-mark
    if(rGenCand.ExistsMarkedState(rit->first.second))
      continue;
    // failure: GPlant-marked state has no GCand-mark
    break;
  }

  // ok if loop passed
  return rit==revmap.end();

}



//IsRelativelyPrefixClosed(rGenPlant,rGenCand)
bool IsRelativelyPrefixClosed(const Generator& rGenPlant, const Generator& rGenCand) {

  FD_DF("IsRelativelyPrefixClosed(\"" <<  rGenPlant.Name() << "\", \"" << rGenCand.Name() << "\")");

  // alphabets must match
  if ( rGenPlant.Alphabet() != rGenCand.Alphabet()) {
    std::stringstream errstr;
    errstr << "Alphabets of generators do not match.";
    throw Exception("IsRelativelyPrefixClosed", errstr.str(), 100);
  }

#ifdef FAUDES_CHECKED
  // generators are meant to be nonblocking
  if ( !IsNonblocking(rGenCand) ||  !IsNonblocking(rGenPlant)) {
    std::stringstream errstr;
    errstr << "Arguments are expected to be nonblocking.";
    throw Exception("IsRelativelyPrefixClosed", errstr.str(), 201);
  }
#endif

#ifdef FAUDES_CHECKED
  // generators are meant to be deterministic
  if ( !IsDeterministic(rGenCand) ||  !IsDeterministic(rGenPlant)) {
    std::stringstream errstr;
    errstr << "Arguments are expected to be deterministic.";
    throw Exception("IsRelativelyPrefixClosed", errstr.str(), 202);
  }
#endif

  // perform composition (variation from cfl_parallel.cpp)
  FD_DF("IsRelativelyPrefixClosed(..): perform product");

  // todo stack
  std::stack< std::pair<Idx,Idx> > todo;
  // current pair, new pair
  std::pair<Idx,Idx> currentstates, newstates;
  // accessible states
  std::set< std::pair<Idx,Idx> > productstates;
  // iterators
  StateSet::Iterator lit1, lit2;
  TransSet::Iterator tit1, tit1_end, tit2, tit2_end;
  std::set< std::pair<Idx,Idx> >::iterator rcit;
  // sense violation of L(GCand) <= L(GPlant)
  bool inclusion12=true;

  // push all combinations of initial states on todo stack
  FD_DF("IsRelativelyPrefixClosed(..): perform product: adding all combinations of initial states to todo");
  for (lit1 = rGenCand.InitStatesBegin(); 
      lit1 != rGenCand.InitStatesEnd(); ++lit1) {
    for (lit2 = rGenPlant.InitStatesBegin(); 
        lit2 != rGenPlant.InitStatesEnd(); ++lit2) {
      currentstates = std::make_pair(*lit1, *lit2);
      todo.push(currentstates);
      productstates.insert(currentstates);
      FD_DF("IsRelativelyPrefixClosed(..): perform product: (" << 
	    *lit1 << "|" << *lit2 << ")");
    }
  }

  // start algorithm
  FD_DF("IsRelativelyPrefixClosed(..): perform product: Product: processing reachable states:");
  while (! todo.empty() && inclusion12) {
    // allow for user interrupt
    LoopCallback();
    // get next reachable state from todo stack
    currentstates = todo.top();
    todo.pop();
    FD_DF("Processing (" << currentstates.first << "|" 
	  << currentstates.second << ")");
    // iterate over all rGenCand transitions
    tit1 = rGenCand.TransRelBegin(currentstates.first);
    tit1_end = rGenCand.TransRelEnd(currentstates.first);
    tit2 = rGenPlant.TransRelBegin(currentstates.second);
    tit2_end = rGenPlant.TransRelEnd(currentstates.second);
    Idx curev1=0;
    bool resolved12=true;
    while((tit1 != tit1_end) && (tit2 != tit2_end)) {
      // sense new event
      if(tit1->Ev != curev1) {
        if(!resolved12) inclusion12=false;
	curev1=tit1->Ev;
        resolved12=false;
      }
      // shared event
      if(tit1->Ev == tit2->Ev) {
        resolved12=true;
        newstates = std::make_pair(tit1->X2, tit2->X2);
        // add to todo list if composition state is new
        rcit = productstates.find(newstates);
        if(rcit == productstates.end()) {
          todo.push(newstates);
          productstates.insert(newstates);
          FD_DF("Product: todo push: (" << newstates.first << "|" 
		<< newstates.second << ")");
        }
        ++tit1;
        ++tit2;
      }
      // try resync tit1
      else if (tit1->Ev < tit2->Ev) {
        ++tit1;
      }
      // try resync tit2
      else if (tit1->Ev > tit2->Ev) {
        ++tit2;
      }
    }
    // last event was not resolved in the product
    if(!resolved12) inclusion12=false;
  }
  // report
#ifdef FAUDES_DEBUG_FUNCTION
  FD_DF("IsRelativelyClosed(): Product: done"); 
  if(!inclusion12) {
    FD_DF("IsRelativelyClosed(): Product: inclusion L(G1) <= L(G2) not satisfied"); 
  }
#endif

  // bail out when inclusion condition is violated
  if(!inclusion12) return false;

  // test all reachable states
  std::set< std::pair<Idx,Idx> >::iterator rit;
  for(rit=productstates.begin(); rit!=productstates.end(); ++rit) {
    // ok: state is GPlant-marked and GCand-marked
    if(rGenPlant.ExistsMarkedState(rit->second)) 
    if(rGenCand.ExistsMarkedState(rit->first))
      continue;
    // ok: state is neither GPlant-marked nor GCand-marked
    if(!rGenPlant.ExistsMarkedState(rit->second)) 
    if(!rGenCand.ExistsMarkedState(rit->first))
      continue;
    // failure: markin mismatch
    break;
  }

  // ok if loop passed
  return rit==productstates.end();

}


// SupRelativelyPrefixClosed(rPlantGen, rCAlph, rSpecGen, rResGen)
void SupRelativelyPrefixClosed(
  const Generator& rPlantGen, 
  const Generator& rSpecGen, 
  Generator& rResGen) 
{

  // CONSISTENCY CHECK: alphabets must match
  if ( rPlantGen.Alphabet() != rSpecGen.Alphabet()) {
    EventSet only_in_plant = rPlantGen.Alphabet() - rSpecGen.Alphabet();
    EventSet only_in_spec = rSpecGen.Alphabet() - rPlantGen.Alphabet();
    only_in_plant.Name("Only_In_Plant");
    only_in_spec.Name("Only_In_Specification");
    std::stringstream errstr;
    errstr << "Alphabets of generators do not match.";
    if(!only_in_plant.Empty())
      errstr << " " << only_in_plant.ToString() << ".";
    if(!only_in_spec.Empty())
      errstr << " " << only_in_spec.ToString() << ".";
    throw Exception("SupCon/SupConNB", errstr.str(), 100);
  }
	
  // CONSISTENCY CHECK: plant and spec must be deterministic
  bool plant_det = rPlantGen.IsDeterministic();
  bool spec_det = rSpecGen.IsDeterministic();
  if ((plant_det == false) && (spec_det == true)) {
    std::stringstream errstr;
    errstr << "Plant generator must be deterministic, "
      << "but is nondeterministic";
    throw Exception("ControllableConsistencyCheck", errstr.str(), 201);
  }
  else if ((plant_det == true) && (spec_det == false)) {
    std::stringstream errstr;
    errstr << "Spec generator must be deterministic, "
       << "but is nondeterministic";
    throw Exception("ControllableConsistencyCheck", errstr.str(), 203);
  }
  else if ((plant_det == false) && (spec_det == false)) {
    std::stringstream errstr;
    errstr << "Plant and spec generator must be deterministic, "
       << "but both are nondeterministic";
    throw Exception("ControllableConsistencyCheck", errstr.str(), 204);
  }

  // HELPERS:
  std::map< std::pair<Idx,Idx>, Idx> rcmap;

  // ALGORITHM:
  SupRelativelyPrefixClosedUnchecked(rPlantGen, rSpecGen, rcmap, rResGen);
}


// SupRelativelyPrefixClosedUnchecked(rPlantGen, rSpecGen, rCompositionMap, rResGen)
void SupRelativelyPrefixClosedUnchecked(
  const Generator& rPlantGen,
  const Generator& rSpecGen,
  std::map< std::pair<Idx,Idx>, Idx>& rCompositionMap, 
  Generator& rResGen) 
{
  FD_DF("SupRelativelyPrefixClosed(" << &rPlantGen << "," << &rSpecGen << ")");

  // PREPARE RESULT:	
  Generator* pResGen = &rResGen;
  if(&rResGen== &rPlantGen || &rResGen== &rSpecGen) {
    pResGen= rResGen.New();
  }
  pResGen->Clear();
  pResGen->Name(CollapsString("SupRpcNB(("+rPlantGen.Name()+"),("+rSpecGen.Name()+"))"));
  pResGen->InjectAlphabet(rPlantGen.Alphabet());

  // ALGORITHM:
  StateSet pmarked;
  StateSet smarked;
  Product(rPlantGen, rSpecGen, rCompositionMap, pmarked, smarked, *pResGen);

  // make resulting generator relatively prefix closed
  StateSet::Iterator six=pResGen->StatesBegin();
  while(six!= pResGen->StatesEnd()) {
    Idx s=*(six++);
    if(!pmarked.Exists(s)) continue;
    if(smarked.Exists(s)) continue;
    pResGen->DelState(s);
  }
  pResGen->Trim();

  // copy result
  if(pResGen != &rResGen) {
    pResGen->Move(rResGen);
    delete pResGen;
  }

}


// IsOmegaRelativelyMarked(rGenPlant,rGenCand)
bool IsRelativelyOmegaMarked(const Generator& rGenPlant, const Generator& rGenCand) {


  FD_DF("IsRelativelyOmegaMarked(\"" <<  rGenPlant.Name() << "\", \"" << rGenCand.Name() << "\")");

  // alphabets must match
  if ( rGenPlant.Alphabet() != rGenCand.Alphabet()) {
    std::stringstream errstr;
    errstr << "Alphabets of generators do not match.";
    throw Exception("RelativelyOmegaMarked", errstr.str(), 100);
  }

#ifdef FAUDES_CHECKED
  // generators are meant to be nonblocking
  if ( !IsOmegaTrim(rGenCand) ||  !IsOmegaTrim(rGenPlant)) {
    std::stringstream errstr;
    errstr << "Arguments are expected to be nonblocking.";
    throw Exception("IsRelativelyOmegaMarked", errstr.str(), 201);
  }
#endif

#ifdef FAUDES_CHECKED
  // generators are meant to be deterministic
  if ( !IsDeterministic(rGenCand) ||  !IsDeterministic(rGenPlant)) {
    std::stringstream errstr;
    errstr << "Arguments are expected to be deterministic.";
    throw Exception("IsRelativelyOmegaMarked", errstr.str(), 202);
  }
#endif

  
  // perform composition
  std::map< std::pair<Idx,Idx> , Idx> revmap;
  Generator product;
  product.StateNamesEnabled(false);
  StateSet markCand;
  StateSet markPlant;
  Product(rGenPlant,rGenCand,revmap,markPlant,markCand,product);

  // find all relevant SCCs
  SccFilter umfilter(SccFilter::FmIgnoreTrivial | SccFilter::FmStatesAvoid| SccFilter::FmStatesRequire, 
    markCand,markPlant);
  std::list<StateSet> umsccs;
  StateSet umroots;
  ComputeScc(product,umfilter,umsccs,umroots); 

  // report
  std::list<StateSet>::iterator ssit=umsccs.begin();
  for(;ssit!=umsccs.end(); ++ssit) {
    FD_DF("IsRelativelyOmegaMarked(): GPlant-marked scc without GCand-mark: " << ssit->ToString());
  }  

  // result is true if no problematic SCCs exist
  return umsccs.size()==0;


}




// IsOmegaRelativelyClosed(rGenPlant,rGenCand)
bool IsRelativelyOmegaClosed(const Generator& rGenPlant, const Generator& rGenCand) {


  FD_DF("IsRelativelyOmegaClosed(\"" <<  rGenPlant.Name() << "\", \"" << rGenCand.Name() << "\")");

  // alphabets must match
  if ( rGenPlant.Alphabet() != rGenCand.Alphabet()) {
    std::stringstream errstr;
    errstr << "Alphabets of generators do not match.";
    throw Exception("RelativelyOmegaClosed", errstr.str(), 100);
  }

#ifdef FAUDES_CHECKED
  // generators are meant to be nonblocking
  if( !IsOmegaTrim(rGenCand) ) {
    std::stringstream errstr;
    errstr << "Argument \"" << rGenCand.Name() << "\" is not omegatrim.";
    throw Exception("IsRelativelyOmegaClosed", errstr.str(), 201);
  }
  if( !IsOmegaTrim(rGenPlant) ) {
    std::stringstream errstr;
    errstr << "Argument \"" << rGenPlant.Name() << "\" is not omega-trim.";
    throw Exception("IsRelativelyOmegaClosed", errstr.str(), 201);
  }
#endif


  // the trivial case: if B1 is empty it is relatively closed
  // (we must treat this case because empty generators are not regarded deterministic)
  if(rGenCand.Empty()) {
    FD_DF("IsRelativelyOmegaClosed(..): empty candidate: pass");
    return true;
  }

  // the trivial case: if B2 is empty but B1 is not empty, the test failed
  // (we must treat this case because empty generators are not regarded deterministic)
  if(rGenPlant.Empty()) {
    FD_DF("IsRelativelyOmegaClosed(..): non-empty candidate. empty plant: fail");
    return false;
  }

#ifdef FAUDES_CHECKED
  // generators are meant to be deterministic
  if ( !IsDeterministic(rGenCand) ||  !IsDeterministic(rGenPlant)) {
    std::stringstream errstr;
    errstr << "Arguments are expected to be deterministic.";
    throw Exception("IsRelativelyOmegaClosed", errstr.str(), 202);
  }
#endif

  // doit
  return IsRelativelyOmegaClosedUnchecked(rGenPlant,rGenCand);
}

  
// IsOmegaRelativelyClosed(rGenPlant,rGenCand)
bool IsRelativelyOmegaClosedUnchecked(const Generator& rGenPlant, const Generator& rGenCand) {

  // perform composition (variant of cfl_parallel.cpp)
  std::map< std::pair<Idx,Idx> , Idx> revmap;
  Generator product;
  product.StateNamesEnabled(false);
  StateSet mark1;
  StateSet mark2;

  // shared alphabet
  product.InjectAlphabet(rGenCand.Alphabet());

  // todo stack
  std::stack< std::pair<Idx,Idx> > todo;
  // current pair, new pair
  std::pair<Idx,Idx> currentstates, newstates;
  // state
  Idx tmpstate;
  // iterators  
  StateSet::Iterator lit1, lit2;
  TransSet::Iterator tit1, tit1_end, tit2, tit2_end;
  std::map< std::pair<Idx,Idx>, Idx>::iterator rcit;
  // sense violation of L(G1) <= L(G2)
  bool inclusion12=true;

  // push all combinations of initial states on todo stack
  FD_DF("IsRelativelyOmegaClosed(): Product composition A");
  for (lit1 = rGenCand.InitStatesBegin(); 
      lit1 != rGenCand.InitStatesEnd(); ++lit1) {
    for (lit2 = rGenPlant.InitStatesBegin(); 
        lit2 != rGenPlant.InitStatesEnd(); ++lit2) {
      currentstates = std::make_pair(*lit1, *lit2);
      todo.push(currentstates);
      tmpstate = product.InsInitState();
      revmap[currentstates] = tmpstate;
      FD_DF("IsRelativelyOmegaClosed(): Product composition A:   (" << *lit1 << "|" << *lit2 << ") -> " 
          << revmap[currentstates]);
    }
  }

  // start algorithm
  while (! todo.empty() && inclusion12) {
    // allow for user interrupt
    LoopCallback();
    // get next reachable state from todo stack
    currentstates = todo.top();
    todo.pop();
    FD_DF("IsRelativelyOmegaClosed(): Product composition B: (" << currentstates.first << "|" 
        << currentstates.second << ") -> " << revmap[currentstates]);
    // iterate over all rGenCand transitions
    tit1 = rGenCand.TransRelBegin(currentstates.first);
    tit1_end = rGenCand.TransRelEnd(currentstates.first);
    tit2 = rGenPlant.TransRelBegin(currentstates.second);
    tit2_end = rGenPlant.TransRelEnd(currentstates.second);
    Idx curev1=0;
    bool resolved12=true;
    while((tit1 != tit1_end) && (tit2 != tit2_end)) {
      // sense new event
      if(tit1->Ev != curev1) {
        if(!resolved12) inclusion12=false;
	curev1=tit1->Ev;
        resolved12=false;
      }
      // shared event
      if (tit1->Ev == tit2->Ev) {
        resolved12=true;
        newstates = std::make_pair(tit1->X2, tit2->X2);
        // add to todo list if composition state is new
        rcit = revmap.find(newstates);
        if (rcit == revmap.end()) {
          todo.push(newstates);
          tmpstate = product.InsState();
          revmap[newstates] = tmpstate;
          FD_DF("IsRelativelyOmegaClosed(): Product composition C: (" << newstates.first << "|" 
             << newstates.second << ") -> " << revmap[newstates]);
        }
        else {
          tmpstate = rcit->second;
        }
        product.SetTransition(revmap[currentstates], tit1->Ev, tmpstate);
        ++tit1;
        ++tit2;
      }
      // try resync tit1
      else if (tit1->Ev < tit2->Ev) {
        ++tit1;
      }
      // try resync tit2
      else if (tit1->Ev > tit2->Ev) {
        ++tit2;
      }
    }
    // last event was not resolved in the product
    if(!resolved12) inclusion12=false;
  }
  // report
#ifdef FAUDES_DEBUG_FUNCTION
  FD_DF("IsRelativelyOmegaClosed(): Product: done"); 
  if(!inclusion12) {
    FD_DF("IsRelativelyOmegaClosed(): Product: inclusion L(G1) <= L(G2) not satisfied"); 
  }
#endif

  // bail out
  if(!inclusion12) return false;

  // retrieve marking from reverse composition map
  std::map< std::pair<Idx,Idx>, Idx>::iterator rit;
  for(rit=revmap.begin(); rit!=revmap.end(); ++rit){
    if(rGenCand.ExistsMarkedState(rit->first.first)) mark1.Insert(rit->second);
    if(rGenPlant.ExistsMarkedState(rit->first.second)) mark2.Insert(rit->second);
  }

  // find all relevant SCCs 1
  SccFilter umfilter12(SccFilter::FmIgnoreTrivial | SccFilter::FmStatesAvoid| SccFilter::FmStatesRequire, 
    mark1,mark2);
  std::list<StateSet> umsccs12;
  StateSet umroots12;
  ComputeScc(product,umfilter12,umsccs12,umroots12); 

  // report
  std::list<StateSet>::iterator ssit=umsccs12.begin();
  for(;ssit!=umsccs12.end(); ++ssit) {
    FD_DF("IsRelativelyOmegaClosed(): G2-marked scc without G1-mark: " << ssit->ToString());
  }  

  // result is false if we found problematic SCCs to exist
  if(umsccs12.size()!=0) return false;

  // find all relevant SCCs 2
  SccFilter umfilter21(SccFilter::FmIgnoreTrivial | SccFilter::FmStatesAvoid| SccFilter::FmStatesRequire, 
    mark2,mark1);
  std::list<StateSet> umsccs21;
  StateSet umroots21;
  ComputeScc(product,umfilter21,umsccs21,umroots21); 

  // report
  ssit=umsccs21.begin();
  for(;ssit!=umsccs21.end(); ++ssit) {
    FD_DF("IsRelativelyOmegaClosed(): G1-marked scc without G2-mark: " << ssit->ToString());
  }  

  // result is false if we found problematic SCCs to exist
  if(umsccs21.size()!=0) return false;

  // done, all tests passed
  FD_DF("IsRelativelyOmegaClosed(): pass");
  return true;
}



} // name space 
