import { AuthClient } from "@dfinity/auth-client";
import { HttpAgent } from "@dfinity/agent";
// You need to import createActor from your declarations
import { createActor } from "../../declarations/Reputation_system_app_backend";

// Set up authentication options
const authOptions = {
  identityProvider: process.env.DFX_NETWORK === "ic" 
    ? "https://identity.ic0.app/#authorize"
    : `http://localhost:4943?canisterId=rdmx6-jaaaa-aaaaa-aaadq-cai#authorize`
};

// Create an async function to initialize auth client
const initAuth = async () => {
  const authClient = await AuthClient.create();
  
  // Login function
  const login = async () => {
    return new Promise((resolve) => {
      authClient.login({
        ...authOptions,
        onSuccess: async () => {
          // Get the authenticated identity
          const identity = authClient.getIdentity();
          
          // Create an agent with this identity
          const agent = new HttpAgent({ identity });
          
          // For local development, fetch the root key
          if (process.env.DFX_NETWORK !== "ic") {
            await agent.fetchRootKey().catch(err => {
              console.warn("Unable to fetch root key. Check your local replica");
              console.error(err);
            });
          }
          
          // Get canister ID from environment variables
          const canisterId = process.env.CANISTER_ID_REPUTATION_SYSTEM_APP_BACKEND;
          
          // Create actor with this agent
          const actor = createActor(canisterId, { agentOptions: { identity } });
          
          resolve({ identity, actor });
        }
      });
    });
  };
  
  return {
    authClient,
    login,
    isAuthenticated: () => authClient.isAuthenticated()
  };
};

export default initAuth;