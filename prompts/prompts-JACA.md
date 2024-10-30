# LTI Pipeline

## Cursor

### Prompt 1
```markdown
We need to create a CI/CD workflow using a GitHub Action for the @backend part of this project. Before starting the CI/CD implementation, scan the code, verify its functionality and ask any questions if needed.
```

I'll help you create a CI/CD workflow for the backend. After analyzing the provided code, here are my key observations:

1. **Project Structure & Technologies**:
   - Node.js/TypeScript backend
   - PostgreSQL database with Prisma ORM
   - Jest for testing
   - ESLint and Prettier for code quality
   - Express.js for the API server

2. **Key Dependencies** (from package.json):

```18:43:backend/package.json
    "dependencies": {
        "@prisma/client": "^5.13.0",
        "cors": "^2.8.5",
        "dotenv": "^16.4.5",
        "express": "^4.19.2",
        "multer": "^1.4.5-lts.1",
        "swagger-jsdoc": "^6.2.8",
        "swagger-ui-express": "^5.0.0"
    },
    "devDependencies": {
        "@types/cors": "^2.8.17",
        "@types/express": "^4.17.9",
        "@types/jest": "^29.5.12",
        "@types/multer": "^1.4.11",
        "@types/node": "^20.12.12",
        "eslint": "^9.2.0",
        "eslint-config-prettier": "^9.1.0",
        "eslint-plugin-prettier": "^5.1.3",
        "jest": "^29.7.0",
        "prettier": "^3.2.5",
        "prisma": "^5.13.0",
        "ts-jest": "^29.1.2",
        "ts-node": "^9.1.1",
        "ts-node-dev": "^1.1.6",
        "typescript": "^4.9.5"
    }
```


3. **Testing Setup**:
   - Jest configuration is present
   - Test files exist for controllers and services
   - Example test file:

```1:26:backend/src/presentation/controllers/positionController.test.ts
import { getCandidatesByPosition } from './positionController';
import { Request, Response } from 'express';
import { getCandidatesByPositionService } from '../../application/services/positionService';

jest.mock('../../application/services/positionService');

describe('getCandidatesByPosition', () => {
  it('should return 200 and candidates data', async () => {
    const req = { params: { id: '1' } } as unknown as Request;
    const res = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn(),
    } as unknown as Response;

    (getCandidatesByPositionService as jest.Mock).mockResolvedValue([
      { fullName: 'John Doe', currentInterviewStep: 'Technical Interview', averageScore: 4 },
    ]);

    await getCandidatesByPosition(req, res);

    expect(res.status).toHaveBeenCalledWith(200);
    expect(res.json).toHaveBeenCalledWith([
      { fullName: 'John Doe', currentInterviewStep: 'Technical Interview', averageScore: 4 },
    ]);
  });
});
```


4. **Database**:
   - PostgreSQL database with connection string in schema.prisma
   - Prisma migrations are present
   - Seed data available

Before creating the CI/CD workflow, I have a few questions:

1. Do you have any specific Node.js version requirements for the project?
2. Are there any environment variables that need to be set up in GitHub Secrets (like database credentials)?
3. Do you want to include deployment steps in the workflow, or should it focus only on testing and building?
4. Should we run Prisma migrations as part of the CI/CD process?
5. Are there any specific branches (main/develop) that should trigger the workflow?

Once you provide these details, I can create a comprehensive GitHub Actions workflow that includes:
- Code checkout
- Node.js setup
- Dependencies installation
- Linting
- Testing
- Building
- (Optional) Deployment steps

Would you like me to proceed with creating the workflow based on your answers to these questions?


### Prompt 2
```markdown
1. Use the latest stable version of Node.js
2. The application must be deployed into a AWS EC2 instance, so we'll need secrets for AWS connection.
3. I want to include deployment steps in the workflow as well.
4. Prisma migrations must be executed as part of the CI/CD process.
5. The build steps should be triggered when opening a Pull Request or pushing new changes to an open Pull Request and all the steps (build and deploy) must be executed when merging into the `main` branch.

Verify if there's any other question to clarify before proceed with the code.
```

Thank you for providing the detailed requirements. Let me analyze a few more points before proceeding with the CI/CD workflow implementation:

1. **Database Configuration**:
   From the schema.prisma file, I notice you're using PostgreSQL:

```12:15:backend/prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = "postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@localhost:5432/LTIdb"
}
```

We'll need to set up test database credentials for the CI environment.

2. **Test Coverage**:
   Looking at your test files, you have Jest tests set up. Should we add a minimum test coverage requirement for the CI pipeline?

3. **Build Process**:
   From your package.json, I see you're using TypeScript with the following build commands:

```6:14:backend/package.json
    "scripts": {
        "start": "node dist/index.js",
        "dev": "ts-node-dev --respawn --transpile-only src/index.ts",
        "build": "tsc",
        "test": "jest",
        "prisma:init": "npx prisma init",
        "prisma:generate": "npx prisma generate",
        "start:prod": "npm run build && npm start"
    },
```

We should ensure all these steps are properly sequenced in the workflow.

4. **Environment Variables**:
   Based on your code, we'll need to set up the following secrets in GitHub:
   - `DATABASE_URL` for Prisma
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `EC2_HOST`
   - `EC2_USERNAME`
   - `EC2_SSH_KEY`

5. **Docker**:
   I don't see any Docker configuration in the provided files. Would you like to containerize the application for deployment? This would make the deployment process more consistent and easier to manage.

Please confirm:
1. Should we add Docker support to the project?
2. Would you like to set a minimum test coverage threshold?
3. Should we add any specific AWS security group configurations or other AWS-specific requirements?
4. Do you want to include any specific health checks after deployment?

Once you provide these details, I can create a comprehensive GitHub Actions workflow that includes all the necessary steps for both PR validation and deployment to AWS EC2.


### Prompt 3
```markdown
1. We don't need to add Docker at this point, we'll be deploying the application directly into a EC2 instance.
2. Not at this time.
3. That's not necessary for now, we can use the default AWS Security Group.
4. Yes, include health checks after deployment.
```

Thank you for the clarification. I'll create a comprehensive GitHub Actions workflow for your backend application. Let's break it down into multiple jobs:

1. **PR Validation** (runs on PR)
   - Lint and type check
   - Run tests
   - Build check

2. **Deploy** (runs on merge to main)
   - Build
   - Deploy to EC2
   - Run migrations
   - Health check

Here's the GitHub Actions workflow file:

```yaml:.github/workflows/ci.yml
name: Backend CI/CD

on:
  pull_request:
    paths:
      - 'backend/**'
  push:
    branches:
      - main
    paths:
      - 'backend/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./backend

    services:
      postgres:
        image: postgres:latest
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: './backend/package-lock.json'

      - name: Install dependencies
        run: npm ci

      - name: Generate Prisma Client
        run: npx prisma generate

      - name: Run ESLint
        run: npx eslint . --ext .ts

      - name: Type check
        run: npx tsc --noEmit

      - name: Run tests
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
        run: npm test

      - name: Build check
        run: npm run build

  deploy:
    needs: validate
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./backend

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: './backend/package-lock.json'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Generate Prisma Client
        run: npx prisma generate

      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.EC2_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.EC2_HOST }} >> ~/.ssh/known_hosts

      - name: Deploy to EC2
        env:
          EC2_HOST: ${{ secrets.EC2_HOST }}
          EC2_USERNAME: ${{ secrets.EC2_USERNAME }}
        run: |
          rsync -avz --delete \
            --exclude 'node_modules' \
            --exclude '.git' \
            --exclude '.env' \
            ./ ${{ secrets.EC2_USERNAME }}@${{ secrets.EC2_HOST }}:/home/${{ secrets.EC2_USERNAME }}/backend/

      - name: Setup application on EC2
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: |
          ssh ${{ secrets.EC2_USERNAME }}@${{ secrets.EC2_HOST }} '\
            cd ~/backend && \
            npm ci --production && \
            echo "DATABASE_URL=${{ secrets.DATABASE_URL }}" > .env && \
            npx prisma migrate deploy && \
            pm2 restart backend || pm2 start dist/index.js --name backend'

      - name: Health check
        run: |
          for i in {1..5}; do
            if curl -s http://${{ secrets.EC2_HOST }}:3000/positions; then
              echo "Health check passed"
              exit 0
            fi
            echo "Waiting for service to be up..."
            sleep 10
          done
          echo "Health check failed"
          exit 1
```

You'll need to add the following secrets to your GitHub repository:
1. `EC2_HOST`: Your EC2 instance's public IP or domain
2. `EC2_USERNAME`: The SSH username (usually 'ubuntu' or 'ec2-user')
3. `EC2_SSH_KEY`: The private SSH key to connect to your EC2 instance
4. `DATABASE_URL`: Your production database connection string

Prerequisites on the EC2 instance:
1. Node.js installed
2. PM2 installed globally (`npm install -g pm2`)
3. The correct SSH key added to the authorized_keys

The workflow:
1. Validates PRs by running tests and checks
2. On merge to main, deploys to EC2
3. Runs database migrations
4. Performs health checks
5. Uses PM2 for process management

Would you like me to explain any specific part of the workflow in more detail?


### Prompt 4
```markdown
Migrate @.eslintrc.js to the new configuration file `eslint.config.js` for ESLint v9+
```

I'll help you migrate the ESLint configuration to the new flat config format used in ESLint v9+. Here's the new configuration:

```javascript:backend/eslint.config.js
import prettier from 'eslint-plugin-prettier/recommended';

export default [
  {
    ...prettier,
    ignores: ['dist/', 'node_modules/']
  }
];
```

Key changes made:
1. Renamed `.eslintrc.js` to `eslint.config.js`
2. Changed from CommonJS (`module.exports`) to ESM format
3. Imported the prettier plugin configuration directly
4. Used the new flat config array format
5. Added common ignores (you may want to adjust these based on your needs)

You'll also need to:
1. Update your `package.json` to include `"type": "module"`
2. Make sure you have the latest versions of ESLint and the prettier plugin installed:
```bash
npm install --save-dev eslint@latest eslint-plugin-prettier@latest
```

Note: If you're not ready to use ESM modules, you can also use this CommonJS version:

```javascript:backend/eslint.config.js
const prettier = require('eslint-plugin-prettier/recommended');

module.exports = [
  {
    ...prettier,
    ignores: ['dist/', 'node_modules/']
  }
];
```


### Prompt 5
```markdown
After further analysis, all the steps (build and deploy) must be executed when opening a new PR or new changes are pushed into the opened PR.
```

Thank you for the clarification. I'll modify the GitHub Actions workflow to execute all steps (including deployment) for PRs as well. Here's the updated workflow:

```yaml:.github/workflows/ci.yml
name: Backend CI/CD

on:
  pull_request:
    paths:
      - 'backend/**'
  push:
    branches:
      - main
    paths:
      - 'backend/**'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./backend

    services:
      postgres:
        image: postgres:latest
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: './backend/package-lock.json'

      - name: Install dependencies
        run: npm ci

      - name: Generate Prisma Client
        run: npx prisma generate

      - name: Run ESLint
        run: npx eslint . --ext .ts

      - name: Type check
        run: npx tsc --noEmit

      - name: Run tests
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
        run: npm test

      - name: Build
        run: npm run build

      - name: Setup SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.EC2_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.EC2_HOST }} >> ~/.ssh/known_hosts

      - name: Deploy to EC2
        env:
          EC2_HOST: ${{ secrets.EC2_HOST }}
          EC2_USERNAME: ${{ secrets.EC2_USERNAME }}
        run: |
          rsync -avz --delete \
            --exclude 'node_modules' \
            --exclude '.git' \
            --exclude '.env' \
            ./ ${{ secrets.EC2_USERNAME }}@${{ secrets.EC2_HOST }}:/home/${{ secrets.EC2_USERNAME }}/backend/

      - name: Setup application on EC2
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
        run: |
          ssh ${{ secrets.EC2_USERNAME }}@${{ secrets.EC2_HOST }} '\
            cd ~/backend && \
            npm ci --production && \
            echo "DATABASE_URL=${{ secrets.DATABASE_URL }}" > .env && \
            npx prisma migrate deploy && \
            pm2 restart backend || pm2 start dist/index.js --name backend'

      - name: Health check
        run: |
          for i in {1..5}; do
            if curl -s http://${{ secrets.EC2_HOST }}:3000/positions; then
              echo "Health check passed"
              exit 0
            fi
            echo "Waiting for service to be up..."
            sleep 10
          done
          echo "Health check failed"
          exit 1
```

Key changes made:
1. Removed the separate `validate` and `deploy` jobs and combined them into a single `build-and-deploy` job
2. Removed the condition that limited deployment to main branch pushes
3. Kept all the steps including deployment for both PR and push events

The workflow will now:
1. Run all checks (lint, type check, tests)
2. Build the application
3. Deploy to EC2
4. Run database migrations
5. Perform health checks

For this to work properly, make sure you have all the required secrets set up in your GitHub repository:
- `EC2_HOST`
- `EC2_USERNAME`
- `EC2_SSH_KEY`
- `DATABASE_URL`

Would you like me to explain any specific part of the workflow in more detail?


### Prompt 6
```markdown
How to solve this error when SSH an AWS EC2 instance?
The authenticity of host 'ec2-3-15-234-154.us-east-2.compute.amazonaws.com (3.15.234.154)' can't be established.
ED25519 key fingerprint is SHA256:+Z4/akJSgwFjAiQA0Ukh1W+hDyJT+5TuXym+AK+Am+M.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? 
Host key verification failed.
```

The error "Host key verification failed" occurs because you didn't respond to the security prompt asking whether you want to continue connecting to the unknown host.

When you connect to an EC2 instance for the first time, SSH will ask you to verify the host's fingerprint. You need to type `yes` when prompted.

Try running the command again and when you see this prompt:
```
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Type `yes` and press Enter. This will add the host to your known_hosts file and allow the connection to proceed.

The full sequence should look like:

```bash
ssh -i "AI4Devs-pipeline.pem" ec2-user@ec2-3-15-234-154.us-east-2.compute.amazonaws.com
# When prompted about host authenticity
yes
```

This is a security feature to protect against man-in-the-middle attacks by ensuring you're connecting to the intended server.


### Prompt 7
```markdown
How to install node in AWS EC2 instance
```

Here's how to install Node.js on an AWS EC2 instance (assuming you're using Amazon Linux 2):

1. First, connect to your EC2 instance:
```bash
ssh -i "your-key.pem" ec2-user@your-ec2-instance
```

2. Update your system:
```bash
sudo yum update -y
```

3. Install Node.js using Node Version Manager (nvm). First, install nvm:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
```

4. Activate nvm:
```bash
. ~/.nvm/nvm.sh
```

5. Install the latest LTS version of Node.js:
```bash
nvm install --lts
```

6. Verify the installation:
```bash
node --version
npm --version
```

Alternative Method (using yum):
```bash
# Enable NodeSource repository
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -

# Install Node.js
sudo yum install -y nodejs
```

Notes:
- The nvm method is recommended as it allows you to easily switch between Node.js versions
- If you're using a different Linux distribution, the commands might vary
- Replace `18.x` with your desired Node.js version in the alternative method
- You might need to reconnect to your terminal after installing nvm for it to work properly


### Prompt 8
```markdown
How to install PostgreSQL in AWS EC2 instance and configure it to use port `5432`, database name `LTIdb`, database user `LTIdbUser` and password `XYZ`
```

Here's a step-by-step guide to install and configure PostgreSQL on your AWS EC2 instance:

1. First, update your system:
```bash
sudo yum update -y
```

2. Install PostgreSQL:
```bash
# Add PostgreSQL repository
sudo amazon-linux-extras enable postgresql14

# Install PostgreSQL
sudo yum install postgresql postgresql-server postgresql-devel postgresql-contrib -y

# Initialize the database
sudo postgresql-setup initdb
```

3. Start and enable PostgreSQL service:
```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo systemctl status postgresql
```

4. Configure PostgreSQL to listen on port 5432 (edit postgresql.conf):
```bash
sudo vi /var/lib/pgsql/data/postgresql.conf
```
Find and modify these lines:
```conf
listen_addresses = '*'          # Listen on all available addresses
port = 5432                     # Default port
```

5. Configure client authentication (edit pg_hba.conf):
```bash
sudo vi /var/lib/pgsql/data/pg_hba.conf
```
Add this line at the end:
```conf
host    all             all             0.0.0.0/0               md5
```

6. Create database and user:
```bash
# Switch to postgres user
sudo -u postgres psql

# Create user
CREATE USER LTIdbUser WITH PASSWORD 'XYZ';

# Create database
CREATE DATABASE LTIdb;

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE LTIdb TO LTIdbUser;

# Exit psql
\q
```

7. Restart PostgreSQL to apply changes:
```bash
sudo systemctl restart postgresql
```

8. Configure AWS Security Group:
- Go to EC2 Dashboard
- Select your instance's Security Group
- Add Inbound Rule:
  - Type: Custom TCP
  - Port: 5432
  - Source: Your IP address or appropriate CIDR block

9. Test the connection:
```bash
psql -h localhost -U LTIdbUser -d LTIdb
```

Important Security Notes:
- Replace 'XYZ' with a strong password
- Consider limiting the IP addresses that can access your database in pg_hba.conf
- Make sure your security group rules only allow connections from trusted IP addresses
- Consider using SSL for secure connections
- In production, you might want to use AWS RDS instead of managing PostgreSQL on EC2

To verify the installation:
```bash
# Connect to database
psql -h localhost -U LTIdbUser -d LTIdb

# Check connection info
\conninfo

# List all databases
\l

# Exit
\q
```

### Prompt 9
```markdown
How to fix this error?
sudo: amazon-linux-extras: command not found
```

This error occurs because you might be using Amazon Linux 1 or a different Linux distribution. Let me provide you with alternative methods to install PostgreSQL:

For Amazon Linux 2023:
```bash
# Install PostgreSQL 14
sudo yum install postgresql14 postgresql14-server -y
```

For Amazon Linux 2:
```bash
# Install amazon-linux-extras if it's missing
sudo yum install -y amazon-linux-extras

# Then proceed with PostgreSQL installation
sudo amazon-linux-extras enable postgresql14
sudo yum install postgresql postgresql-server postgresql-devel postgresql-contrib -y
```

For Ubuntu:
```bash
# Add PostgreSQL repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib -y
```

To check which Linux distribution you're using:
```bash
cat /etc/os-release
```

Let me know which distribution you're using, and I can provide the specific commands for your system.


### Prompt 10
```markdown
How to fix this new error
Last metadata expiration check: 0:31:44 ago on Wed Oct 30 03:00:13 2024.
No match for argument: postgresql14
No match for argument: postgresql14-server
Error: Unable to find a match: postgresql14 postgresql14-server
```

Let's try installing PostgreSQL 15 instead, as PostgreSQL 14 might not be available in the default repositories:

```bash
# Install PostgreSQL 15
sudo dnf install -y postgresql15 postgresql15-server

# If the above doesn't work, try this alternative approach:
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql15-server postgresql15
```

After installation:
```bash
# Initialize the database
sudo postgresql-15-setup initdb

# Start and enable the service
sudo systemctl start postgresql-15
sudo systemctl enable postgresql-15
```

If you still get an error, please share the output of:
```bash
cat /etc/os-release
```
This will help me provide the exact commands for your specific Linux distribution.


### Prompt 11
```markdown
The installation was correct, however there's a new error
sudo: postgresql-15-setup: command not found
```

The command name might be slightly different. Let's try these alternative commands:

```bash
# Try this first
sudo /usr/bin/postgresql-setup --initdb

# If that doesn't work, try
sudo postgresql-setup initdb

# If neither works, try finding the exact path
find / -name "*postgresql*setup*" 2>/dev/null
```

If none of these work, we can try initializing the database manually:

```bash
# First, find where PostgreSQL is installed
which postgres

# Create the data directory and set permissions
sudo mkdir -p /var/lib/pgsql/data
sudo chown postgres:postgres /var/lib/pgsql/data

# Initialize as postgres user
sudo -u postgres initdb -D /var/lib/pgsql/data
```

After successful initialization:
```bash
# Start PostgreSQL service
sudo systemctl start postgresql

# Enable PostgreSQL to start on boot
sudo systemctl enable postgresql

# Check status
sudo systemctl status postgresql
```

Let me know which command works for you, and we can proceed with the next steps of configuration.


### Prompt 12
```markdown
Everything went fine, we can proceed with next steps
```

Great! Let's continue with configuring PostgreSQL for your requirements. We'll set up the database, user, and configure the port:

1. First, configure PostgreSQL to listen on port 5432 (edit postgresql.conf):
```bash
sudo vi /var/lib/pgsql/data/postgresql.conf
```

Find and modify/uncomment these lines:
```conf
listen_addresses = '*'          # Listen on all available addresses
port = 5432                     # Default port
```

2. Configure client authentication (edit pg_hba.conf):
```bash
sudo vi /var/lib/pgsql/data/pg_hba.conf
```

Add this line at the end of the file:
```conf
host    all             all             0.0.0.0/0               md5
```

3. Create database and user:
```bash
# Switch to postgres user
sudo -u postgres psql

# Inside psql, run these commands:
CREATE USER "LTIdbUser" WITH PASSWORD 'D1ymf8wyQEGthFR1E9xhCq';
CREATE DATABASE "LTIdb";
GRANT ALL PRIVILEGES ON DATABASE "LTIdb" TO "LTIdbUser";

# Exit psql
\q
```

4. Restart PostgreSQL to apply changes:
```bash
sudo systemctl restart postgresql
```

5. Test the connection:
```bash
psql -h localhost -U LTIdbUser -d LTIdb
# When prompted, enter the password 'XYZ'
```

6. Don't forget to configure your EC2 security group to allow inbound traffic on port 5432 from your desired IP addresses.

Let me know if you encounter any issues with these steps!


### Prompt 13
```markdown
The connection must be always from localhost
```

If the connection will only be from localhost, we can make the configuration more secure. Here's the modified setup:

1. Edit postgresql.conf to only listen on localhost:
```bash
sudo vi /var/lib/pgsql/data/postgresql.conf
```

Find and modify/uncomment these lines:
```conf
listen_addresses = 'localhost'    # Only listen on localhost
port = 5432                      # Default port
```


2. Edit pg_hba.conf for local connections only:
```bash
sudo vi /var/lib/pgsql/data/pg_hba.conf
```

Replace or modify the lines at the end to only allow local connections:
```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all            all                                     peer
host    all            all             127.0.0.1/32            md5
host    all            all             ::1/128                 md5
```


3. Create database and user (if you haven't already):
```bash
# Switch to postgres user
sudo -u postgres psql

# Inside psql, run these commands:
CREATE USER LTIdbUser WITH PASSWORD 'XYZ';
CREATE DATABASE LTIdb;
GRANT ALL PRIVILEGES ON DATABASE LTIdb TO LTIdbUser;

# Exit psql
\q
```


4. Restart PostgreSQL:
```bash
sudo systemctl restart postgresql
```


5. Test the local connection:
```bash
psql -h localhost -U LTIdbUser -d LTIdb
# When prompted, enter the password 'XYZ'
```

With this configuration:
- PostgreSQL will only accept connections from localhost (127.0.0.1)
- You don't need to open port 5432 in your EC2 security group
- It's more secure as no external connections are possible


### Prompt 14
```markdown
I got the following error when connecting to the database with the new user
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  Ident authentication failed for user "LTIdbUser"
```

This error occurs because PostgreSQL is using `peer` or `ident` authentication instead of `md5`. Let's fix this by modifying the `pg_hba.conf` file:

1. Edit pg_hba.conf:
```bash
sudo vi /var/lib/pgsql/data/pg_hba.conf
```


2. Replace or modify the authentication methods to use `md5` instead of `peer` or `ident`:
```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all            all                                     md5
host    all            all             127.0.0.1/32            md5
host    all            all             ::1/128                 md5
```


3. Restart PostgreSQL to apply changes:
```bash
sudo systemctl restart postgresql
```


4. Try connecting again:
```bash
psql -h localhost -U LTIdbUser -d LTIdb
# When prompted, enter the password 'XYZ'
```


The key changes here are:
- Changed `peer` to `md5` for local connections
- This allows password authentication instead of system user authentication
- All other settings remain the same

Now you should be able to connect using your password.


### Prompt 15
```markdown
There's a different error to connect to the database
psql: error: connection to server at "localhost" (127.0.0.1), port 5432 failed: FATAL:  password authentication failed for user "LTIdbUser"
```

This error means the password you're using doesn't match the one set for the `LTIdbUser`. Let's reset the password:

1. Connect to PostgreSQL as the postgres user:
```bash
sudo -u postgres psql
```


2. Reset the password for LTIdbUser:
```sql
ALTER USER LTIdbUser WITH PASSWORD 'XYZ';

# Verify the user exists and its attributes
\du LTIdbUser

# Exit psql
\q
```


3. Try connecting again:
```bash
psql -h localhost -U LTIdbUser -d LTIdb
# When prompted, enter the password 'XYZ'
```


If you want to verify the connection details without exposing the password, you can create a connection string:
```bash
export PGPASSWORD='XYZ'
psql -h localhost -U LTIdbUser -d LTIdb
```


Make sure to:
- Type the password exactly as 'XYZ' (case sensitive)
- Check for any hidden spaces or special characters
- Ensure you're using the correct username (LTIdbUser is case sensitive)



```
How to install pm2 in the AWS EC2 instance?
```

Here's how to install PM2 on your AWS EC2 instance:

1. Using npm (if Node.js is already installed):
```bash
# Install PM2 globally
sudo npm install -g pm2

# Verify installation
pm2 --version
```


2. Basic PM2 commands after installation:
```bash
# Start an application
pm2 start app.js

# Start with a specific name
pm2 start app.js --name "my-app"

# Enable startup script (to run PM2 when server reboots)
pm2 startup

# Save current process list
pm2 save

# Other useful commands
pm2 list          # List all processes
pm2 monit         # Monitor all processes
pm2 logs          # Display logs
pm2 stop all      # Stop all processes
pm2 restart all   # Restart all processes
```


If you get any permission errors during installation, you might need to:
```bash
# Fix npm permissions
sudo chown -R $USER:$GROUP ~/.npm
sudo chown -R $USER:$GROUP ~/.config

# Then try installing PM2 again
sudo npm install -g pm2
```


Remember to run `pm2 startup` and `pm2 save` after starting your applications to ensure they restart automatically if the server reboots.



```
There's a new error:
sudo: npm: command not found
which actually works when doing npm without sudo
```

Since npm is installed under your user (likely via nvm) and not system-wide, you should install PM2 without sudo. Here's the correct way:

```bash
# Install PM2 globally for your user
npm install -g pm2

# Verify installation
pm2 --version
```



If you need to set up PM2 startup script later, use this approach:
```bash
# Generate startup script (this will give you a sudo command to run)
pm2 startup

# Run the command that PM2 gives you (it will look something like this):
sudo env PATH=$PATH:/home/ec2-user/.nvm/versions/node/v{YOUR_NODE_VERSION}/bin pm2 startup systemd -u ec2-user --hp /home/ec2-user

# Save your process list
pm2 save
```



Common PM2 commands (no sudo needed):
```bash
pm2 start app.js
pm2 list
pm2 monit
pm2 logs
pm2 stop all
pm2 restart all
```

The key is to avoid using sudo with npm when you've installed Node.js via nvm, as it's a user-level installation.
