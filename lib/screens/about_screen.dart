import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('关于我们', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 应用信息
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C9678), Color(0xFF46B696)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C9678).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 背景装饰
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // 内容
                  Column(
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.note_alt_outlined,
                            size: 40,
                            color: Color(0xFF2C9678),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'InkRoot',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '版本 1.0.0',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '静待沉淀，蓄势鸣响。\n你的每一次落笔，都是未来生长的根源。',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 应用介绍
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
              children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '关于InkRoot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'InkRoot是一款现代化的笔记与创作应用，致力于为创作者提供简洁、强大的写作环境。我们相信写作不仅是记录，更是思考和创造的过程。',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                const Text(
                    'InkRoot 诞生于2025年，我们希望将最新的技术与传统写作体验相融合，打造既有数字化便利又保留纸笔质感的创作工具。',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                    '我们重视用户隐私和数据安全，所有功能设计都以保护用户创作内容为首要原则。InkRoot支持本地存储、端到端加密和多种云服务，确保您的创作随时随地安全可得。',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
              ),
            ),

            // 核心功能
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                ),
              ],
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                      Icon(
                        Icons.star_outline,
                        color: theme.primaryColor,
                        size: 20,
                    ),
                      const SizedBox(width: 10),
                      Text(
                        '核心功能',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                    ),
                ),
              ],
            ),
                  const SizedBox(height: 16),
                  const Text(
                    'InkRoot专注于为各类创作者提供灵活、强大的工具，无论您是作家、学生、研究人员还是内容创作者。',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildFeatureTag(context, '所见即所得编辑', Icons.edit_outlined),
                      _buildFeatureTag(context, 'Markdown支持', Icons.code),
                      _buildFeatureTag(context, '知识图谱', Icons.account_tree_outlined),
                      _buildFeatureTag(context, '自动备份', Icons.backup_outlined),
                      _buildFeatureTag(context, '多端同步', Icons.sync_outlined),
                      _buildFeatureTag(context, '数据加密', Icons.lock_outlined),
                      _buildFeatureTag(context, '高度可定制', Icons.settings_outlined),
                    ],
                  ),
                ],
              ),
            ),

            // 联系方式
            Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                        Icons.phone_outlined,
                        color: theme.primaryColor,
                        size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                        '联系我们',
                        style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
                  const Text(
                    '我们非常重视用户的反馈和建议。如果您有任何问题、意见或合作意向，请随时与我们联系。',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    context,
                    icon: Icons.email_outlined,
                    label: '电子邮件',
                    value: 'sdwxgzh@126.com',
                    onTap: () => _launchURL('mailto:sdwxgzh@126.com'),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    context,
                    icon: Icons.support_agent_outlined,
                    label: '客户支持',
                    value: 'sdwxgzh@126.com',
                    onTap: () => _launchURL('mailto:sdwxgzh@126.com'),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    context,
                    icon: Icons.location_on_outlined,
                    label: '交流地址',
                    value: '陕西省西安市雁塔区丈八街道',
                    onTap: () {},
                  ),
        ],
              ),
            ),

            // 社交链接
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    context,
                    icon: Icons.access_time,
                    onTap: () => _showPlatformDialog(context, 'QQ'),
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    context,
                    icon: Icons.code,
                    onTap: () => _showPlatformDialog(context, 'GitHub'),
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    context,
                    icon: Icons.email_outlined,
                    onTap: () => _showPlatformDialog(context, '邮箱'),
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    context,
                    icon: Icons.chat_outlined,
                    onTap: () => _showPlatformDialog(context, '微信'),
                  ),
                ],
              ),
            ),

            // 版权信息
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: const [
                  Text(
                    '© 2025 InkRoot Inc. 保留所有权利',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '陕ICP备XXXXXXXX号-1',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '版本 1.0.0 (build 2025072001)',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTag(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
              color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                  style: TextStyle(
                      fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showPlatformDialog(BuildContext context, String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在打开$platform...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 40,
          right: 40,
        ),
      ),
    );
  }
} 