import { describe, it, expect, beforeEach } from 'vitest';

// Mock blockchain state
let blockchain = {
  users: new Map(),
  services: new Map(),
  projects: new Map(),
  projectParticipants: new Map(),
  userIdNonce: 0,
  serviceIdNonce: 0,
  projectIdNonce: 0,
};

// Mock contract functions
const timeBankingContract = {
  registerUser: (skills: string[]) => {
    const userId = ++blockchain.userIdNonce;
    blockchain.users.set(userId, {
      address: `user${userId}`,
      timeBalance: 0,
      reputation: 100,
      skills,
    });
    return { ok: userId };
  },
  
  offerService: (description: string, duration: number) => {
    const serviceId = ++blockchain.serviceIdNonce;
    blockchain.services.set(serviceId, {
      provider: blockchain.userIdNonce,
      seeker: 0,
      duration,
      description,
      status: 'offered',
    });
    return { ok: serviceId };
  },
  
  acceptService: (serviceId: number) => {
    const service = blockchain.services.get(serviceId);
    if (service && service.status === 'offered') {
      service.seeker = blockchain.userIdNonce;
      service.status = 'accepted';
      blockchain.services.set(serviceId, service);
      return { ok: true };
    }
    return { error: 'Service not found or not in offered state' };
  },
  
  completeService: (serviceId: number) => {
    const service = blockchain.services.get(serviceId);
    if (service && service.status === 'accepted') {
      const provider = blockchain.users.get(service.provider);
      const seeker = blockchain.users.get(service.seeker);
      if (provider && seeker) {
        provider.timeBalance += service.duration;
        seeker.timeBalance -= service.duration;
        service.status = 'completed';
        blockchain.services.set(serviceId, service);
        blockchain.users.set(service.provider, provider);
        blockchain.users.set(service.seeker, seeker);
        return { ok: true };
      }
    }
    return { error: 'Service not found or not in accepted state' };
  },
  
  rateService: (serviceId: number, rating: number) => {
    const service = blockchain.services.get(serviceId);
    if (service && service.status === 'completed') {
      const ratedUser = blockchain.users.get(service.provider);
      if (ratedUser) {
        ratedUser.reputation = Math.floor((ratedUser.reputation * 9 + rating * 20) / 10);
        blockchain.users.set(service.provider, ratedUser);
        return { ok: true };
      }
    }
    return { error: 'Service not found or not completed' };
  },
  
  createProject: (name: string, description: string, requiredSkills: string[], totalHours: number) => {
    const projectId = ++blockchain.projectIdNonce;
    blockchain.projects.set(projectId, {
      name,
      description,
      requiredSkills,
      totalHours,
      status: 'open',
    });
    return { ok: projectId };
  },
  
  contributeToProject: (projectId: number, hours: number) => {
    const project = blockchain.projects.get(projectId);
    const user = blockchain.users.get(blockchain.userIdNonce);
    if (project && user && project.status === 'open' && user.timeBalance >= hours) {
      user.timeBalance -= hours;
      const key = `${projectId}-${blockchain.userIdNonce}`;
      const currentContribution = blockchain.projectParticipants.get(key) || { hoursContributed: 0 };
      currentContribution.hoursContributed += hours;
      blockchain.projectParticipants.set(key, currentContribution);
      blockchain.users.set(blockchain.userIdNonce, user);
      
      const totalContributed = Array.from(blockchain.projectParticipants.values())
          .reduce((sum, contribution) => sum + contribution.hoursContributed, 0);
      
      if (totalContributed >= project.totalHours) {
        project.status = 'completed';
        blockchain.projects.set(projectId, project);
      }
      
      return { ok: true };
    }
    return { error: 'Unable to contribute to project' };
  },
};

describe('Time Banking System', () => {
  beforeEach(() => {
    // Reset blockchain state before each test
    blockchain = {
      users: new Map(),
      services: new Map(),
      projects: new Map(),
      projectParticipants: new Map(),
      userIdNonce: 0,
      serviceIdNonce: 0,
      projectIdNonce: 0,
    };
  });
  
  it('allows users to register and offer services', () => {
    const user1Register = timeBankingContract.registerUser(['coding', 'teaching']);
    const user2Register = timeBankingContract.registerUser(['gardening', 'cooking']);
    const offerService = timeBankingContract.offerService('Web development', 2);
    
    expect(user1Register.ok).toBe(1);
    expect(user2Register.ok).toBe(2);
    expect(offerService.ok).toBe(1);
    expect(blockchain.users.size).toBe(2);
    expect(blockchain.services.size).toBe(1);
  });
  
  it('allows users to create and contribute to community projects', () => {
    timeBankingContract.registerUser(['coding', 'teaching']);
    timeBankingContract.registerUser(['gardening', 'cooking']);
    const createProject = timeBankingContract.createProject('Community Garden', 'Create a community garden', ['gardening', 'planning'], 10);
    
    expect(createProject.ok).toBe(1);
    
    // Give users some time balance to contribute
    blockchain.users.get(1)!.timeBalance = 10;
    blockchain.users.get(2)!.timeBalance = 10;
    
    blockchain.userIdNonce = 1; // Set current user to the first user
    const contribute1 = timeBankingContract.contributeToProject(1, 5);
    blockchain.userIdNonce = 2; // Set current user to the second user
    const contribute2 = timeBankingContract.contributeToProject(1, 5);
    
    expect(contribute1.ok).toBe(true);
    expect(contribute2.ok).toBe(true);
    
    const project = blockchain.projects.get(1);
    expect(project?.status).toBe('completed');
    
    const user1Contribution = blockchain.projectParticipants.get('1-1');
    const user2Contribution = blockchain.projectParticipants.get('1-2');
    expect(user1Contribution?.hoursContributed).toBe(5);
    expect(user2Contribution?.hoursContributed).toBe(5);
  });
});

