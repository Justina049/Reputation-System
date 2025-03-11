import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import HashMap "mo:base/HashMap";
// import Principal "mo:base/Principal";
// import HashMap "mo:base/HashMap";

// actor ReputationSystem {

//   stable var reputationStorage: [(Principal, Nat)] = [];
//   stable var tokenStorage: [(Principal, Nat)] = [];
  
//   var reputationScores = HashMap.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);
//   var tokenBalances = HashMap.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);

//   // Function to check a user's reputation score
//   public query func getReputation(user: Principal) : async Nat {
//   switch (reputationScores.get(user)) {
//     case (?score) score;
//     case null 0;
//   }
//   };

//   public func giveReputation(to: Principal) : async Text {
//     let caller = Principal.fromActor(ReputationSystem);

//     if (caller == to ) {
//       return "You cannot give reputation to yourself!";
//     };
//     let currentScore = switch (reputationScores.get(to)) {
//       case (?score) score;
//       case null 0;
//     };

//     reputationScores.put(to, currentScore + 1);
//     return "Reputation successfully given!";
//   }
  
// };



actor ReputationSystem {
  let admin = Principal.fromActor(ReputationSystem);
  


  // Stable storage for persistence across upgrades
  stable var reputationStorage: [(Principal, Nat)] = [];
  stable var lastActiveTimeStorage: [(Principal, Time.Time)] = [];
  stable var verifiedUserStorage: [(Principal, Bool)] = [];
  stable var ratingHistoryStorage: [((Principal, Principal), Nat)] = [];

  // Runtime HashMaps
  var reputationScores = HashMap.HashMap<Principal, Nat>(10, Principal.equal, Principal.hash);
  var lastActiveTimes = HashMap.HashMap<Principal, Time.Time>(10, Principal.equal, Principal.hash);
  var verifiedUsers = HashMap.HashMap<Principal, Bool>(10, Principal.equal, Principal.hash);
  var ratingHistory = HashMap.HashMap<(Principal, Principal), Nat>(10, 
    func(a, b) {Principal.equal(a.0, b.0) and Principal.equal(a.1, b.1) },
    func (k) {Principal.hash(k.0) + Principal.hash(k.1)}
  );

  let decayRate = 5;
  let weightTreshold = 10;
  }



