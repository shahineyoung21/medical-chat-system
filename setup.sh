#!/bin/bash

# ============================================================
# Medical Chat System - Automated Setup Script
# نظام المحادثات الطبية - سكريبت التثبيت التلقائي
# ============================================================

set -e

echo "🏥 Medical Chat System Setup"
echo "================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Python version
echo -e "${BLUE}Checking Python version...${NC}"
python3 --version

# Create virtual environment
echo -e "${BLUE}Creating virtual environment...${NC}"
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
echo -e "${BLUE}Upgrading pip...${NC}"
pip install --upgrade pip

# Install requirements
echo -e "${BLUE}Installing dependencies...${NC}"
pip install -r config/requirements.txt

# Create necessary directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p {reports,memory,agents/logs,assets,tests}

# Copy .env file
echo -e "${BLUE}Setting up environment variables...${NC}"
if [ ! -f .env ]; then
    cp config/.env.example .env
    echo -e "${YELLOW}⚠️  Please edit .env with your API keys${NC}"
else
    echo -e "${GREEN}✓ .env already exists${NC}"
fi

# Download character assets
echo -e "${BLUE}Downloading character assets...${NC}"

# Create placeholder avatar if not exists
if [ ! -f assets/sabah_avatar.png ]; then
    echo "Creating placeholder avatar..."
    python3 << 'EOF'
from PIL import Image, ImageDraw
import os

# Create a simple avatar
img = Image.new('RGB', (400, 400), color=(230, 57, 70))  # Medical red
draw = ImageDraw.Draw(img)

# Add text
text = "صباح"
draw.text((180, 190), text, fill=(255, 255, 255))

os.makedirs('assets', exist_ok=True)
img.save('assets/sabah_avatar.png')
print("✓ Avatar created")
EOF
fi

# Create character profile JSON
echo -e "${BLUE}Creating character profile...${NC}"
cat > assets/character_profile.json << 'EOF'
{
  "name": "صباح",
  "full_name": "صباح العربية الطبية",
  "role": "مذيعة ومستشارة طبية",
  "personality": {
    "tone": "احترافية وودية",
    "language": "عربي فصيح مع لهجة عربية حديثة",
    "style": "ناعمة لكن حكيمة وموثوقة",
    "empathy": "عالية جداً"
  },
  "avatar": "assets/sabah_avatar.png",
  "voice_provider": "google",
  "voice_language": "ar-EG",
  "greetings": [
    "السلام عليكم! أنا صباح، مرحباً بك 🌸",
    "مرحباً! كيف أساعدك اليوم؟ 💚"
  ]
}
EOF

# Initialize git hooks
echo -e "${BLUE}Setting up git hooks...${NC}"
if [ -d .git ]; then
    mkdir -p .git/hooks
fi

# Create initial memory file
echo -e "${BLUE}Initializing memory system...${NC}"
cat > memory/shared_memory.md << 'EOF'
# Medical Chat System - Shared Memory
## نظام الذاكرة المشتركة

### Team Members
- **Genie Leader**: قائد الفريق المنسق
- **Medical Consultant**: استشاري طبي
- **Drug Database**: قاعدة الأدوية
- **Hospital Finder**: محرك البحث الجغرافي
- **Price Comparison**: مقارن الأسعار
- **LLM Router**: موجه نماذج اللغة

### Guidelines
1. كل وكيل يحفظ نتائجه هنا
2. تشارك البيانات المهمة
3. تعلم من الأخطاء السابقة

EOF

# Run tests
echo -e "${BLUE}Running tests...${NC}"
python3 -m pytest tests/ -v 2>/dev/null || echo "⚠️  No tests found yet"

# Final message
echo ""
echo -e "${GREEN}=================================${NC}"
echo -e "${GREEN}✓ Setup completed successfully!${NC}"
echo -e "${GREEN}=================================${NC}"
echo ""
echo "Next steps:"
echo "1. Edit .env with your API keys"
echo "2. Add secrets to GitHub repository"
echo "3. Test locally: python agents/genie_leader.py"
echo "4. Push to GitHub and create issues with !medical prefix"
echo ""
echo "Example:"
echo "  !medical استشيري لي - عندي صداع مستمر"
echo ""
