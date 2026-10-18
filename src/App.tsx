import React, { useState, useRef, useEffect } from 'react';
import { 
  Send, 
  ShieldAlert, 
  Info, 
  RotateCcw, 
  HeartHandshake, 
  Sparkles,
  FileText,
  X
} from 'lucide-react';

interface ChatMessage {
  id: string;
  text: string;
  isUser: boolean;
  time: string;
}

const INITIAL_MESSAGES: ChatMessage[] = [
  {
    id: 'welcome-1',
    text: 'مرحبًا، أنا صباح — واجهة تجريبية للمحادثة. لا أقدم تشخيصًا أو علاجًا، ولا أتصل بطبيب أو قاعدة بيانات. رجاءً لا تكتب بيانات شخصية أو صحية حقيقية هنا.',
    isUser: false,
    time: 'الآن',
  },
];

const DEMO_REPLY =
  'وصلت رسالتك إلى نموذج العرض المحلي فقط. هذا التطبيق لا يحلل الأعراض، ولا يقدم تشخيصًا أو علاجًا أو توصية دوائية، ولا يرسل المحادثة إلى أي خدمة. للمعلومات الصحية تواصل مع مختص مؤهل، وللطوارئ تواصل مع خدمات الطوارئ المحلية.';

const QUICK_SUGGESTIONS = [
  'ما هو دور تطبيق صباح؟',
  'أشعر بصداع خفيف منذ الصباح',
  'أريد معرفة أقرب خدمات طوارئ',
];

export default function App() {
  const [messages, setMessages] = useState<ChatMessage[]>(INITIAL_MESSAGES);
  const [inputText, setInputText] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [showInfoModal, setShowInfoModal] = useState(false);
  
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const scrollToBottom = (behavior: ScrollBehavior = 'smooth') => {
    messagesEndRef.current?.scrollIntoView({ behavior });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isTyping]);

  const handleSendMessage = (textToSend?: string) => {
    const text = (textToSend ?? inputText).trim();
    if (!text) return;

    const userMessage: ChatMessage = {
      id: `msg-${Date.now()}-user`,
      text,
      isUser: true,
      time: new Date().toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInputText('');
    setIsTyping(true);

    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
    }

    // Simulate response delay matching native feel
    setTimeout(() => {
      const botMessage: ChatMessage = {
        id: `msg-${Date.now()}-bot`,
        text: DEMO_REPLY,
        isUser: false,
        time: new Date().toLocaleTimeString('ar-EG', { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages((prev) => [...prev, botMessage]);
      setIsTyping(false);
    }, 400);
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  const handleTextareaChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setInputText(e.target.value);
    e.target.style.height = 'auto';
    e.target.style.height = `${Math.min(e.target.scrollHeight, 120)}px`;
  };

  const handleResetChat = () => {
    setMessages(INITIAL_MESSAGES);
    setInputText('');
  };

  return (
    <div 
      className="flex flex-col h-screen w-full bg-[#F5F8F7] text-[#17312F] max-w-2xl mx-auto shadow-sm"
      dir="rtl"
      data-testid="chat-screen"
    >
      {/* AppBar / Header */}
      <header className="bg-[#F5F8F7] border-b border-[#E5ECE9] px-4 py-3 flex items-center justify-between sticky top-0 z-20">
        <div className="flex items-center gap-3">
          {/* BrandMark */}
          <div 
            className="w-[42px] h-[42px] rounded-[15px] bg-[#176B66] flex items-center justify-center text-white shadow-sm flex-shrink-0"
            title="صباح - الرعاية والتوعية الصحية"
          >
            <ShieldAlert className="w-[24px] h-[24px]" strokeWidth={2.2} />
          </div>

          {/* Title & Subtitle */}
          <div className="flex flex-col">
            <h1 className="text-[20px] font-bold text-[#17312F] leading-tight">
              صباح
            </h1>
            <span className="text-[12px] text-[#647773] font-medium">
              محادثة تجريبية محلية
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {/* Reset button */}
          <button
            onClick={handleResetChat}
            className="p-2 text-[#647773] hover:text-[#176B66] hover:bg-[#E1F1ED] rounded-full transition-colors"
            title="إعادة بدء المحادثة"
            aria-label="إعادة بدء المحادثة"
          >
            <RotateCcw className="w-4 h-4" />
          </button>

          {/* Info Modal Button */}
          <button
            onClick={() => setShowInfoModal(true)}
            className="p-2 text-[#647773] hover:text-[#176B66] hover:bg-[#E1F1ED] rounded-full transition-colors"
            title="عن تطبيق صباح وخطة النظام"
            aria-label="معلومات التطبيق"
          >
            <Info className="w-4 h-4" />
          </button>

          {/* DemoBadge */}
          <div className="bg-[#E1F1ED] text-[#145C55] text-[11px] font-bold px-[11px] py-[6px] rounded-[20px] select-none">
            نسخة تجريبية
          </div>
        </div>
      </header>

      {/* Safety Notice Banner */}
      <div className="px-4 pt-3 pb-1">
        <div className="bg-[#FFF5DF] border border-[#EED69D] rounded-[16px] p-[13px] flex items-start gap-[9px] shadow-xs">
          <Info className="w-5 h-5 text-[#8B6415] shrink-0 mt-[1px]" />
          <p className="text-[12px] font-semibold text-[#634C1F] leading-relaxed">
            نموذج واجهة فقط — لا تشخيص ولا علاج. لا تُدخل معلومات شخصية أو صحية حقيقية.
          </p>
        </div>
      </div>

      {/* Message List */}
      <main 
        className="flex-1 overflow-y-auto px-4 py-3 space-y-3"
        data-testid="message-list"
      >
        {messages.map((message) => {
          const isUser = message.isUser;
          return (
            <div
              key={message.id}
              className={`flex w-full ${isUser ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[84%] rounded-[18px] px-[15px] py-[12px] shadow-2xs transition-all ${
                  isUser
                    ? 'bg-[#DCEFEB] border border-[#C9E4DE] text-[#223532] rounded-br-[5px]'
                    : 'bg-white border border-[#E5ECE9] text-[#223532] rounded-bl-[5px]'
                }`}
              >
                <p className="text-[14px] leading-[1.6] whitespace-pre-wrap">
                  {message.text}
                </p>
                <div 
                  className={`text-[10px] mt-1 flex items-center gap-1 ${
                    isUser ? 'text-[#3E7D73] justify-end' : 'text-[#7D8F8B] justify-start'
                  }`}
                >
                  <span>{message.time}</span>
                  {!isUser && <span className="opacity-75">• صباح</span>}
                </div>
              </div>
            </div>
          );
        })}

        {isTyping && (
          <div className="flex justify-start">
            <div className="bg-white border border-[#E5ECE9] text-[#647773] rounded-[18px] rounded-bl-[5px] px-4 py-3 flex items-center gap-2 shadow-2xs">
              <span className="text-xs">صباح تكتب</span>
              <span className="flex gap-1 items-center">
                <span className="w-1.5 h-1.5 rounded-full bg-[#176B66] animate-bounce [animation-delay:-0.3s]"></span>
                <span className="w-1.5 h-1.5 rounded-full bg-[#176B66] animate-bounce [animation-delay:-0.15s]"></span>
                <span className="w-1.5 h-1.5 rounded-full bg-[#176B66] animate-bounce"></span>
              </span>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </main>

      {/* Quick Suggestion Chips */}
      {messages.length <= 3 && (
        <div className="px-4 py-1 flex items-center gap-2 overflow-x-auto no-scrollbar pb-1">
          <span className="text-[11px] text-[#71817D] shrink-0 font-medium flex items-center gap-1">
            <Sparkles className="w-3 h-3 text-[#176B66]" /> أمثلة سريعة:
          </span>
          {QUICK_SUGGESTIONS.map((suggestion, index) => (
            <button
              key={index}
              onClick={() => handleSendMessage(suggestion)}
              className="text-[12px] bg-white border border-[#DCE6E2] text-[#176B66] hover:bg-[#E1F1ED] px-3 py-1.5 rounded-full whitespace-nowrap transition-colors shadow-2xs"
            >
              {suggestion}
            </button>
          ))}
        </div>
      )}

      {/* Message Composer */}
      <footer className="p-3 bg-[#F5F8F7] border-t border-[#E5ECE9]">
        <div className="flex items-end gap-2 max-w-full">
          <div className="flex-1 relative">
            <textarea
              ref={textareaRef}
              rows={1}
              value={inputText}
              onChange={handleTextareaChange}
              onKeyDown={handleKeyDown}
              placeholder="اكتب رسالة تجريبية…"
              data-testid="message-field"
              className="w-full bg-white text-[#223532] placeholder-[#8C9B98] text-[15px] rounded-[22px] border border-[#DCE6E2] focus:border-[#176B66] focus:ring-1 focus:ring-[#176B66] focus:outline-none px-4 py-[13px] resize-none leading-normal transition-all"
            />
          </div>

          <button
            onClick={() => handleSendMessage()}
            disabled={!inputText.trim()}
            data-testid="send-message"
            title="إرسال الرسالة"
            aria-label="إرسال الرسالة"
            className="w-[48px] h-[48px] rounded-full bg-[#176B66] text-white flex items-center justify-center shrink-0 disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#125551] active:scale-95 transition-all shadow-sm"
          >
            <Send className="w-5 h-5 rtl:rotate-180" />
          </button>
        </div>

        {/* Local-only footer disclaimer */}
        <div className="text-center pt-2 pb-1">
          <span className="text-[11px] text-[#71817D]">
            لا تُحفظ الرسائل بعد إغلاق التطبيق
          </span>
        </div>
      </footer>

      {/* Information Modal */}
      {showInfoModal && (
        <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4 backdrop-blur-2xs">
          <div 
            className="bg-white rounded-2xl max-w-md w-full max-h-[85vh] overflow-y-auto p-5 shadow-xl border border-[#E5ECE9] text-right"
            dir="rtl"
          >
            <div className="flex items-center justify-between border-b border-[#E5ECE9] pb-3 mb-4">
              <div className="flex items-center gap-2">
                <HeartHandshake className="w-5 h-5 text-[#176B66]" />
                <h3 className="font-bold text-lg text-[#17312F]">حول نظام محادثة صباح</h3>
              </div>
              <button
                onClick={() => setShowInfoModal(false)}
                className="p-1 text-[#647773] hover:text-[#17312F] rounded-full"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4 text-sm text-[#4A5D5A] leading-relaxed">
              <div className="bg-[#E1F1ED] p-3 rounded-xl border border-[#C9E4DE]">
                <h4 className="font-bold text-[#145C55] mb-1 flex items-center gap-1.5">
                  <ShieldAlert className="w-4 h-4" /> تنبيه أمان وإخلاء مسؤولية
                </h4>
                <p className="text-xs text-[#145C55]">
                  هذا التطبيق واجهة تجريبية محلية فقط (Prototype Demo). لا يتصل بأي طبيب أو قاعدة بيانات، ولا يقدم أي تشخيص أو علاج أو توصية دوائية.
                </p>
              </div>

              <div>
                <h4 className="font-bold text-[#17312F] mb-1 flex items-center gap-1.5">
                  <FileText className="w-4 h-4 text-[#176B66]" /> البنية الأصلية للمشروع
                </h4>
                <p className="text-xs">
                  تمت إعادة كتابة التطبيق من Flutter الأصلي إلى React + TypeScript مع الحفاظ التام على التصميم، الألوان، تدفق المحادثة، والرسائل التوضيحية.
                </p>
              </div>

              <div className="bg-[#F5F8F7] p-3 rounded-xl border border-[#E5ECE9]">
                <h4 className="font-bold text-[#17312F] text-xs mb-1">
                  المميزات المتوفرة في النسخة الحالية:
                </h4>
                <ul className="text-xs list-disc list-inside space-y-1 text-[#647773]">
                  <li>واجهة عربية كاملة بتصميم RTL دقيق</li>
                  <li>حفظ الرسائل في الذاكرة المؤقتة أثناء الجلسة</li>
                  <li>ردود توجيهية وإرشادية للأمان الصحي</li>
                  <li>توافق متكامل مع الهواتف الذكية وأجهزة الحاسوب</li>
                </ul>
              </div>

              <div className="text-center pt-2">
                <button
                  onClick={() => setShowInfoModal(false)}
                  className="w-full bg-[#176B66] text-white py-2.5 px-4 rounded-xl font-bold text-sm hover:bg-[#125551] transition-colors"
                >
                  إغلاق والمتابعة
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
